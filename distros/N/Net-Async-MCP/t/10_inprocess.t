use strict;
use warnings;
use Test2::V0;

use Future;
use IO::Async::Loop;
use Scalar::Util qw( weaken );
use Net::Async::MCP;
use MCP::Server;
use MCP::Server::Transport::HTTP;

# Create test MCP server with tools
my $server = MCP::Server->new(name => 'TestServer');

$server->tool(
  name         => 'echo',
  description  => 'Echo the input text',
  input_schema => {
    type       => 'object',
    properties => { message => { type => 'string' } },
    required   => ['message'],
  },
  code => sub { return "Echo: $_[1]->{message}" },
);

$server->tool(
  name         => 'add',
  description  => 'Add two numbers',
  input_schema => {
    type       => 'object',
    properties => {
      a => { type => 'number' },
      b => { type => 'number' },
    },
    required => ['a', 'b'],
  },
  code => sub { return $_[1]->{a} + $_[1]->{b} },
);

# Create MCP client with InProcess transport
my $loop = IO::Async::Loop->new;
my $mcp = Net::Async::MCP->new(server => $server);
$loop->add($mcp);

# Test initialize (current protocol: server/discover + _meta)
{
  my $result = $mcp->initialize->get;
  is($result->{_meta}{'io.modelcontextprotocol/serverInfo'}{name},
    'TestServer', 'server name in result._meta serverInfo');
  ok($result->{capabilities}, 'capabilities returned');
  is($mcp->server_info->{name}, 'TestServer', 'server_info accessor');
}

# ping is a transport-level liveness no-op in the current protocol (no
# client-addressable JSON-RPC ping); it must succeed.
{
  my $ok = $mcp->ping->get;
  ok($ok, 'ping (transport-level liveness) succeeds');
}

# Test list_tools
{
  my $tools = $mcp->list_tools->get;
  is(scalar @$tools, 2, 'two tools listed');

  my %by_name = map { $_->{name} => $_ } @$tools;
  ok($by_name{echo}, 'echo tool exists');
  ok($by_name{add}, 'add tool exists');
  is($by_name{echo}{description}, 'Echo the input text', 'echo description');
}

# Test call_tool - echo
{
  my $result = $mcp->call_tool('echo', { message => 'hello world' })->get;
  ok(!$result->{isError}, 'echo not an error');
  is($result->{content}[0]{type}, 'text', 'content type is text');
  is($result->{content}[0]{text}, 'Echo: hello world', 'echo result correct');
}

# Test call_tool - add
{
  my $result = $mcp->call_tool('add', { a => 3, b => 4 })->get;
  ok(!$result->{isError}, 'add not an error');
  is($result->{content}[0]{text}, '7', 'add result correct');
}

# Test call_tool - nonexistent tool
{
  my $f = $mcp->call_tool('nonexistent', {});
  ok($f->failure, 'calling nonexistent tool fails');
  like($f->failure, qr/not found/i, 'error mentions not found');
}

# Test list_prompts (empty)
{
  my $prompts = $mcp->list_prompts->get;
  is(scalar @$prompts, 0, 'no prompts');
}

# Test list_resources (empty)
{
  my $resources = $mcp->list_resources->get;
  is(scalar @$resources, 0, 'no resources');
}

# Test subscriptions_listen with an InProcess server that has no notification
# transport attached: MCP::Server::_handle_listen only honours the request when
# the server's transport supports notifications, otherwise it responds with
# JSON-RPC error -32601 (METHOD_NOT_FOUND). We verify that subscriptions_listen
# builds a _meta-carrying request (so it reaches the handler and fails with
# "method not found" rather than a protocol error) and surfaces that failure.
{
  my $f = $mcp->subscriptions_listen({ toolsListChanged => 1 });
  ok($f->failure, 'subscriptions_listen fails on a server without notification transport');
  like($f->failure, qr/not found/i, 'failure is JSON-RPC METHOD_NOT_FOUND');
}

# The other half: a server that does have a notification capable transport of
# its own. MCP::Server::_handle_listen then answers with an
# MCP::Server::Subscription object instead of a JSON-RPC response, expecting the
# transport to serve it as a notification stream. In process there is no stream,
# so the transport has to name its own limitation rather than blame the server
# for a malformed response - the message is what tells a caller whether to fix
# their server or pick another transport.
{
  my $streaming = MCP::Server->new(name => 'StreamingServer');
  $streaming->transport(
    MCP::Server::Transport::HTTP->new(server => $streaming, streaming => 1));
  ok($streaming->transport->notifications,
    'the attached server transport supports notifications');

  my $client = Net::Async::MCP->new(server => $streaming);
  $loop->add($client);

  my $f = $client->subscriptions_listen({ toolsListChanged => 1 });
  ok($f->failure, 'subscriptions_listen fails on a notification capable server too');
  like($f->failure, qr/cannot carry server-initiated notifications/,
    'the failure names the in-process transport as the limitation');
  like($f->failure, qr{subscriptions/listen is not usable},
    'and says which method is out of reach here');
  unlike($f->failure, qr/Invalid response/,
    'and does not accuse the server of a malformed response');
}

# The InProcess transport has no headers to mirror anything into, so the client
# must not spend a tools/list on resolving what it could not use anyway
{
  package Test::CountingServer;
  sub new { bless { methods => [] }, shift }
  sub handle {
    my ( $self, $request ) = @_;
    push @{ $self->{methods} }, $request->{method};
    return undef unless defined $request->{id};
    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      result  => { content => [ { type => 'text', text => 'ok' } ] },
    };
  }
  sub methods { $_[0]{methods} }
}

{
  my $counting = Test::CountingServer->new;
  my $client = Net::Async::MCP->new(server => $counting);
  $loop->add($client);

  ok(!$client->{transport}->mirrors_header_params,
    'the InProcess transport mirrors no header params');

  # A tool this client never listed: over HTTP this is what triggers the
  # schema lookup, here it must trigger nothing but the call itself
  $client->call_tool('never_listed', { region => 'europe-west1' })->get;
  is($counting->methods, ['tools/call'],
    'calling an unlisted tool sends no tools/list on a transport without headers');
}

# The InProcess transport is not an IO::Async::Notifier at all: it has no
# configure and no events, and a direct call and its return value leave nothing
# a notification could arrive over. So an on_notification on an in-process
# client stays without effect - which is only true for as long as the client
# asks what its transport takes before handing anything over, rather than
# handing on whatever the caller set.
{
  my $client = Net::Async::MCP->new(server => $server, on_notification => sub { });
  $loop->add($client);

  ok(lives { $client->configure(on_notification => sub { }) },
    'an on_notification configured on an in-process client reaches no transport')
    or note $@;

  ok(!$client->{transport}->can('configure'),
    'there being no configure on that transport to reach in the first place');
  is($client->call_tool('echo', { message => 'still here' })->get->{content}[0]{text},
    'Echo: still here', 'and the client goes on working');
}

done_testing;
