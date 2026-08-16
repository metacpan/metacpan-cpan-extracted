use strict;
use warnings;
use Test2::V0;

use Future;
use IO::Async::Loop;
use Scalar::Util qw( weaken );
use Net::Async::MCP;
use MCP::Server;

# Transport-independent client behaviour: request building, retries,
# renegotiation and event dispatch that do not depend on which transport
# carries them. The transports each get their own file (t/10_inprocess.t,
# t/20_stdio.t, t/30_http.t); what follows pins the client logic that is the
# same over all of them, scripted through stub servers in this process.

# The revision this client speaks, spelled out rather than read from
# MCP::Constants: what this client sends, and what it can be renegotiated into,
# is decided by the request shapes it builds, and taking the installed server
# library's word for it here would let these tests pass for a reason that has
# nothing to do with the client. It is the one entry of
# @SPOKEN_PROTOCOL_VERSIONS in Net::Async::MCP, and if that list ever names a
# different revision this is the second place to change.
my $spoken = '2026-07-28';

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

# The client speaks the newest revision it builds requests for by default
is($mcp->protocol_version, $spoken, 'defaults to the revision this client speaks');

# ...and which revision that is, this distribution says. The assertion above
# cannot tell that from a client reading MCP::Constants, since the installed
# MCP names the same revision today; only an MCP::Constants naming a different
# one can, and it has to be in @INC before Net::Async::MCP is loaded - hence a
# child perl. Following that constant is the bug being guarded against: the
# moment MCP learns a newer revision, a client still building this one's
# requests would put the new version string on them.
{
  require File::Temp;
  my $fake = File::Temp->newdir;
  mkdir "$fake/MCP" or die "mkdir $fake/MCP: $!";
  open my $out, '>', "$fake/MCP/Constants.pm" or die "$fake/MCP/Constants.pm: $!";
  print $out <<'CONSTANTS';
package MCP::Constants;
use strict;
use warnings;
use constant PROTOCOL_VERSION             => '2027-01-01';
use constant UNSUPPORTED_PROTOCOL_VERSION => -32022;
1;
CONSTANTS
  close $out or die "$fake/MCP/Constants.pm: $!";

  # The fake ahead of everything else, so it is the MCP::Constants the child
  # finds, and the rest of this process's @INC behind it so the child finds
  # Net::Async::MCP where this test did.
  my @inc = map {; "-I$_" } "$fake", grep { !ref } @INC;
  open my $child, '-|', $^X, @inc, '-e',
    'use Net::Async::MCP; print Net::Async::MCP->new->protocol_version'
    or die "cannot run $^X: $!";
  my $reported = do { local $/; <$child> };
  close $child;

  is($reported, $spoken,
    'the default stays the spoken revision even where MCP::Constants names another');
}

# And declares nothing it cannot serve: an empty declaration is what keeps a
# conforming server from sending inputRequests this client could not answer.
is($mcp->client_capabilities, {}, 'declares no client capabilities by default');

# Reconfiguring with an undefined protocol version must fall back to the
# default instead of blanking the client: every request carries
# protocolVersion in _meta, and MCP::Server answers a missing one with -32602.
{
  $mcp->configure(protocol_version => undef);
  is($mcp->protocol_version, $spoken,
    'undef protocol_version falls back to the default');

  my $f = $mcp->list_tools;
  ok(!$f->failure, 'a request after configure still carries a usable protocol version')
    or diag $f->failure;
}

# A server whose discover result carries no _meta at all. MCP::Server always
# sends one, so this needs a stub, but a foreign server may not: server_info
# must then default to {} without the client mutating the result it hands back
# to the caller.
{
  package Test::NoMetaServer;
  sub new { bless {}, shift }
  sub handle {
    my ( $self, $request ) = @_;
    return undef unless defined $request->{id};
    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      result  => { capabilities => {} },
    };
  }
}

{
  my $bare = Net::Async::MCP->new(server => Test::NoMetaServer->new);
  $loop->add($bare);

  my $result = $bare->initialize->get;
  is($bare->server_info, {}, 'server_info defaults to {} when the result has no _meta');
  ok(!exists $result->{_meta}, 'initialize does not autovivify _meta into the result');
}

# Tool arguments annotated with x-mcp-header have to be mirrored into
# Mcp-Param-{Name} headers by the HTTP binding, and which arguments those are
# follows from the tool's input schema. The client reads them out of the schema
# so that every binding gets the same answer; this is the same walk
# MCP::Tool::_header_params does on the server, whose result the server checks
# the headers against.
{
  my $params = Net::Async::MCP::_header_params({
    type       => 'object',
    properties => {
      service => { type => 'string' },
      region  => { type => 'string',  'x-mcp-header' => 'Region' },
      dry_run => { type => 'boolean', 'x-mcp-header' => 'Dry-Run' },
      options => {
        type       => 'object',
        properties => {
          label => { type => 'string', 'x-mcp-header' => 'Label' },
          plain => { type => 'string' },
        },
      },
    },
  });

  is($params, [
    { name => 'Dry-Run', path => ['dry_run'],           type => 'boolean' },
    { name => 'Label',   path => ['options', 'label'],  type => 'string' },
    { name => 'Region',  path => ['region'],            type => 'string' },
  ], 'only annotated properties are extracted, nested ones with their full path');

  is(Net::Async::MCP::_header_params({ type => 'object' }), [],
    'a schema without properties has no header params');
  is(Net::Async::MCP::_header_params(undef), [],
    'and neither has a tool that ships no input schema at all');

  # x-mcp-header is only meaningful under a chain of "properties" keys, so an
  # annotation anywhere else is not a header param and must not be mirrored
  is(Net::Async::MCP::_header_params({
    type       => 'object',
    properties => {
      tags => {
        type  => 'array',
        items => { type => 'string', 'x-mcp-header' => 'Tag' },
      },
    },
  }), [], 'an annotation outside the properties chain is ignored');
}

# list_tools is what fills that cache, so a client that has listed its tools
# knows which arguments need a header without asking again
{
  my $annotated = MCP::Server->new(name => 'AnnotatedServer');
  $annotated->tool(
    name         => 'deploy',
    description  => 'Deploy a service',
    input_schema => {
      type       => 'object',
      properties => {
        service => { type => 'string' },
        region  => { type => 'string', 'x-mcp-header' => 'Region' },
      },
    },
    code => sub { return 'deployed' },
  );
  $annotated->tool(
    name         => 'status',
    description  => 'Report status',
    input_schema => { type => 'object', properties => { service => { type => 'string' } } },
    code => sub { return 'ok' },
  );

  my $client = Net::Async::MCP->new(server => $annotated);
  $loop->add($client);

  $client->list_tools->get;
  is($client->{tool_header_params}{deploy},
    [ { name => 'Region', path => ['region'], type => 'string' } ],
    'list_tools caches the header params of an annotated tool');
  is($client->{tool_header_params}{status}, [],
    'and an empty list for a tool without annotations, so it is never looked up again');
}

# Client capabilities are a promise to the server: it may only send an
# inputRequest for something the client declared. Declaring them therefore has
# to reach the server on the wire, not just sit in an accessor - a client that
# says it does sampling and then never sends it in _meta would never be asked,
# and one whose declaration got lost the other way round would be asked for
# something it cannot do.
{
  package Test::RecordingServer;
  sub new { bless { requests => [] }, shift }
  sub requests { $_[0]{requests} }
  sub handle {
    my ( $self, $request ) = @_;
    push @{ $self->{requests} }, $request;
    return undef unless defined $request->{id};
    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      result  => { tools => [] },
    };
  }
}

{
  my $recording = Test::RecordingServer->new;
  my $capabilities = { sampling => {}, elicitation => {} };
  my $client = Net::Async::MCP->new(
    server              => $recording,
    client_capabilities => $capabilities,
  );
  $loop->add($client);

  is($client->client_capabilities, $capabilities,
    'client_capabilities are readable back');

  $client->list_tools->get;
  is($recording->requests->[0]{params}{_meta}{'io.modelcontextprotocol/clientCapabilities'},
    $capabilities, 'and travel in the _meta of a real request, not just initialize');

  # Same fallback as protocol_version: blanking the attribute must not put an
  # undef where the server expects a capabilities object.
  $client->configure(client_capabilities => undef);
  is($client->client_capabilities, {},
    'undef client_capabilities falls back to an empty declaration');

  $client->list_tools->get;
  is($recording->requests->[1]{params}{_meta}{'io.modelcontextprotocol/clientCapabilities'},
    {}, 'and the empty declaration is what goes on the wire afterwards');
}

# A server that pages its lists. MCP allows it, the installed MCP::Server never
# does it, so seeing the second page at all needs a stub. It records the cursor
# of every request, because appending a second page the client fetched without
# passing the cursor back would be a different (and broken) thing entirely.
{
  package Test::PagingServer;

  # method => [ result key, first page, second page ]
  my %LISTS = (
    'tools/list' => [ 'tools',
      [ { name => 'alpha', inputSchema => { type => 'object',
            properties => { region => { type => 'string', 'x-mcp-header' => 'Region' } } } } ],
      [ { name => 'beta', inputSchema => { type => 'object',
            properties => { zone => { type => 'string', 'x-mcp-header' => 'Zone' } } } } ],
    ],
    'prompts/list'   => [ 'prompts',   [ { name => 'first' } ], [ { name => 'second' } ] ],
    'resources/list' => [ 'resources', [ { uri => 'file:///one' } ], [ { uri => 'file:///two' } ] ],
  );

  sub new { bless { cursors => [] }, shift }
  sub cursors { $_[0]{cursors} }

  sub handle {
    my ( $self, $request ) = @_;
    return undef unless defined $request->{id};

    my $list = $LISTS{ $request->{method} }
      or return { jsonrpc => '2.0', id => $request->{id},
                  error => { code => -32601, message => 'Method not found' } };

    my ( $key, @pages ) = @$list;
    my $cursor = $request->{params}{cursor};
    push @{ $self->{cursors} }, $cursor;

    my $page = defined $cursor ? 1 : 0;
    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      result  => {
        $key => $pages[$page],
        $page == 0 ? ( nextCursor => 'page-2' ) : (),
      },
    };
  }
}

{
  my $paging = Test::PagingServer->new;
  my $client = Net::Async::MCP->new(server => $paging);
  $loop->add($client);

  my $tools = $client->list_tools->get;
  is([ map { $_->{name} } @$tools ], ['alpha', 'beta'],
    'both pages of a paginated tool list are returned, in server order');
  is($paging->cursors, [ undef, 'page-2' ],
    'the first page is asked for without a cursor and the second with the one the server gave');

  # The header param cache is what call_tool resolves Mcp-Param headers from,
  # so a tool that only appears on the second page has to be in it too -
  # otherwise pagination would fix the returned list and leave calls to
  # late-page tools rejected by the server for a missing header.
  is($client->{tool_header_params}{alpha},
    [ { name => 'Region', path => ['region'], type => 'string' } ],
    'the schema cache knows the tool from the first page');
  is($client->{tool_header_params}{beta},
    [ { name => 'Zone', path => ['zone'], type => 'string' } ],
    'and the one that only exists on the second page');

  is([ map { $_->{name} } @{ $client->list_prompts->get } ], ['first', 'second'],
    'list_prompts merges its pages too');
  is([ map { $_->{uri} } @{ $client->list_resources->get } ],
    ['file:///one', 'file:///two'], 'and so does list_resources');
}

# A server that never advances: every page comes back with the cursor it just
# handed out. Following that forever is not an option, and neither is stopping
# quietly with what has arrived - a short list that looks complete is the bug
# pagination support was added to remove.
{
  package Test::LoopingServer;
  sub new { bless { requests => 0 }, shift }
  sub requests { $_[0]{requests} }
  sub handle {
    my ( $self, $request ) = @_;
    return undef unless defined $request->{id};
    $self->{requests}++;
    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      result  => { tools => [ { name => 'again' } ], nextCursor => 'stuck' },
    };
  }
}

{
  my $looping = Test::LoopingServer->new;
  my $client = Net::Async::MCP->new(server => $looping);
  $loop->add($client);

  my $f = $client->list_tools;
  ok($f->failure, 'a server that repeats its cursor fails the list instead of looping');
  like($f->failure, qr/pagination/, 'and the failure says pagination is why');
  like($f->failure, qr/stuck/, 'naming the cursor that came round again');

  is($looping->requests, 2,
    'the repeat is caught on the request that proves it, not after a page limit');
  is($client->{tool_header_params}, undef,
    'and a failed walk leaves no partial schema cache behind');
}

# SEP-2322 lets a server answer with an input_required result instead of a
# final one, asking the client for something and to call again. MCP::Server
# only produces one from a primitive that returns MCP::Primitive::input_required
# itself, so scripting the exchange needs a stub: it answers each request with
# the next result on its list, repeats the last one for as long as it is asked,
# and keeps every request it saw - the retry is the whole point, so what it
# carries is what has to be checked.
{
  package Test::InputServer;
  sub new {
    my ( $class, @results ) = @_;
    return bless { results => \@results, requests => [] }, $class;
  }
  sub requests { $_[0]{requests} }
  sub handle {
    my ( $self, $request ) = @_;
    push @{ $self->{requests} }, $request;
    return undef unless defined $request->{id};
    my $result = @{ $self->{results} } > 1
      ? shift @{ $self->{results} }
      : $self->{results}[0];
    return { jsonrpc => '2.0', id => $request->{id}, result => $result };
  }
}

# An input_required result with a requestState and nothing else asks for
# nothing but the call again. The state is sealed and bound by the server, so
# the only correct thing to do with it is hand it back exactly as it arrived.
{
  my $state  = 'eyJwYXlsb2FkIjp7Im5hbWUiOiJlZGdlIn19.c2lnbmF0dXJl';
  my $server = Test::InputServer->new(
    { resultType => 'input_required', requestState => $state },
    { content => [ { type => 'text', text => 'deleted' } ] },
  );

  my $asked = 0;
  my $client = Net::Async::MCP->new(
    server           => $server,
    on_input_request => sub { $asked++; return { action => 'accept' } },
  );
  $loop->add($client);

  my $result = $client->call_tool('delete_release', { name => 'edge' })->get;
  is($result->{content}[0]{text}, 'deleted',
    'the caller sees the final result, not the input_required on the way to it');

  my @calls = @{ $server->requests };
  is(scalar @calls, 2, 'which took exactly one retry');
  is($calls[1]{params}{requestState}, $state,
    'the retry mirrors the requestState back unchanged');
  is($calls[1]{params}{name}, 'delete_release',
    'and repeats the original request rather than sending a bare retry');
  is($calls[1]{params}{arguments}, { name => 'edge' }, 'arguments included');
  ok(!exists $calls[1]{params}{inputResponses},
    'a result that asked for no input is answered with no inputResponses');
  ok(!exists $calls[0]{params}{requestState},
    'and the first attempt carried no state at all');
  is($asked, 0, 'a pure retry never troubles the input request handler');
}

# The other half: a result that names what it wants. Each request goes to
# on_input_request under the method it asks for, and the answers go back under
# the keys the server chose - those keys are how the server reads its own
# responses back, so getting them wrong loses the answer entirely.
{
  my $server = Test::InputServer->new(
    {
      resultType    => 'input_required',
      requestState  => 'STATE-1',
      inputRequests => {
        confirm => {
          method => 'elicitation/create',
          params => {
            message         => 'Really delete edge?',
            requestedSchema => { type => 'object' },
          },
        },
        pick => {
          method => 'sampling/createMessage',
          params => { messages => [ { role => 'user' } ] },
        },
      },
    },
    { content => [ { type => 'text', text => 'deleted' } ] },
  );

  my @asked;
  my $client = Net::Async::MCP->new(
    server              => $server,
    client_capabilities => { elicitation => {}, sampling => {} },
    on_input_request    => sub {
      my ( $mcp, $method, $params ) = @_;
      push @asked, [ $mcp, $method, $params ];

      # A handler that has to go and ask someone answers with a Future, which
      # is the whole reason this client waits for one.
      return Future->done({ action => 'accept', content => { ok => \1 } })
        if $method eq 'elicitation/create';
      return { role => 'assistant', content => { type => 'text', text => 'edge' } };
    },
  );
  $loop->add($client);

  my $result = $client->call_tool('delete_release', { name => 'edge' })->get;
  is($result->{content}[0]{text}, 'deleted',
    'the round trip ends in the final result');

  is([ map { $_->[1] } @asked ], [ 'elicitation/create', 'sampling/createMessage' ],
    'every input request reaches the handler, named by the method it asks for');
  is($asked[0][0], exact_ref($client), 'called with the client as first argument');
  is($asked[0][2]{message}, 'Really delete edge?',
    'and with the params of that very request');

  my $retry = $server->requests->[1]{params};
  is($retry->{inputResponses}, {
    confirm => { action => 'accept', content => { ok => \1 } },
    pick    => { role => 'assistant', content => { type => 'text', text => 'edge' } },
  }, 'the answers travel back under the keys the server asked by');
  is($retry->{requestState}, 'STATE-1', 'alongside the state, still untouched');
}

# Nothing about this is specific to tools/call - it sits in the one place every
# request goes through - and a result without a requestState must be retried
# without one rather than with an empty or undefined key.
{
  my $server = Test::InputServer->new(
    {
      resultType    => 'input_required',
      inputRequests => { confirm => { method => 'elicitation/create', params => {} } },
    },
    { messages => [ { role => 'user' } ] },
  );

  my $client = Net::Async::MCP->new(
    server              => $server,
    client_capabilities => { elicitation => {} },
    on_input_request    => sub { return { action => 'accept' } },
  );
  $loop->add($client);

  my $result = $client->get_prompt('review', { file => 'x.pm' })->get;
  is($result->{messages}[0]{role}, 'user', 'get_prompt walks the round trip too');

  my $retry = $server->requests->[1]{params};
  ok(!exists $retry->{requestState},
    'a result without a requestState is retried without one');
  is($retry->{inputResponses}{confirm}, { action => 'accept' },
    'and the answer is still there');
  is($retry->{name}, 'review', 'on top of the original params of prompts/get');
}

# A server may legitimately ask again after being answered, so the retry is a
# loop - and a loop needs an end. Handing back what has arrived is not one:
# an input_required result looks to a caller like a final result whose content
# went missing.
{
  my $server = Test::InputServer->new(
    { resultType => 'input_required', requestState => 'never-ending' },
  );
  my $client = Net::Async::MCP->new(server => $server);
  $loop->add($client);

  my $f = $client->call_tool('forever', {});
  ok($f->failure, 'a server that never stops asking fails the call');
  like($f->failure, qr/input_required more than 8 times/,
    'and the failure says how far it was followed');
  is(scalar @{ $server->requests }, 9,
    'which is eight retries after the original request, and then no more');
}

# inputRequests with nothing to answer them. Passing the input_required result
# back to the caller instead would be the same silence, only harder to find.
{
  my $server = Test::InputServer->new(
    {
      resultType    => 'input_required',
      inputRequests => { confirm => { method => 'elicitation/create', params => {} } },
    },
  );
  my $client = Net::Async::MCP->new(
    server              => $server,
    client_capabilities => { elicitation => {} },
  );
  $loop->add($client);

  my $f = $client->call_tool('confirm_me', {});
  ok($f->failure, 'input requests with no handler set fail the call');
  like($f->failure, qr/on_input_request/, 'the failure names what is missing');
  like($f->failure, qr/confirm/, 'and which request went unanswered');
  is(scalar @{ $server->requests }, 1, 'nothing is retried');
}

# Declaring a capability is a promise both ways: the server may only ask for
# what was declared, and a client that quietly answered anyway would be
# rewarding a server for breaking it.
{
  my $server = Test::InputServer->new(
    {
      resultType    => 'input_required',
      inputRequests => { pick => { method => 'sampling/createMessage', params => {} } },
    },
  );

  my $asked  = 0;
  my $client = Net::Async::MCP->new(
    server              => $server,
    client_capabilities => { elicitation => {} },
    on_input_request    => sub { $asked++; return { action => 'accept' } },
  );
  $loop->add($client);

  my $f = $client->call_tool('sample_me', {});
  ok($f->failure, 'an input request for an undeclared capability fails the call');
  like($f->failure, qr/did not declare/,
    'and is named as the server violation it is');
  like($f->failure, qr{sampling/createMessage}, 'naming what was asked for');
  is($asked, 0, 'the handler is never troubled with it');
}

# An input_required result with neither half leaves nothing to answer and
# nothing to send back, so a retry would repeat the first request exactly.
{
  my $server = Test::InputServer->new({ resultType => 'input_required' });
  my $client = Net::Async::MCP->new(server => $server);
  $loop->add($client);

  my $f = $client->read_resource('file:///one');
  ok($f->failure, 'an input_required result that asks for nothing fails the call');
  like($f->failure, qr/neither inputRequests nor requestState/,
    'saying what the server left out');
  is(scalar @{ $server->requests }, 1,
    'and no retry that could not have differed from the first attempt');
}

# What the handler returns goes on the wire as it is, so a handler that
# returned nothing usable has to be caught here rather than by the server.
{
  my $server = Test::InputServer->new(
    {
      resultType    => 'input_required',
      inputRequests => { confirm => { method => 'elicitation/create', params => {} } },
    },
  );
  my $client = Net::Async::MCP->new(
    server              => $server,
    client_capabilities => { elicitation => {} },
    on_input_request    => sub { return },
  );
  $loop->add($client);

  my $f = $client->call_tool('confirm_me', {});
  ok($f->failure, 'a handler that answers with nothing fails the call');
  like($f->failure, qr/not a HashRef/, 'saying what was expected');
  like($f->failure, qr/confirm/, 'and for which request');
}

# A server that does not speak the revision a request was made with answers
# UNSUPPORTED_PROTOCOL_VERSION (-32022) and names the ones it does speak in
# error.data.supported. MCP::Server never refuses a version its own
# MCP::Constants lists, so scripting the refusal needs a stub: this one turns
# down every request whose _meta carries a version it was not told to accept,
# and answers the rest with the version it was asked in - which is how the
# retry can be told from the first attempt.
{
  package Test::VersionServer;
  sub new {
    my ( $class, %args ) = @_;
    return bless { %args, requests => [] }, $class;
  }
  sub requests { $_[0]{requests} }
  sub handle {
    my ( $self, $request ) = @_;
    push @{ $self->{requests} }, $request;
    return undef unless defined $request->{id};

    my $version = ( $request->{params}{_meta} // {} )
      ->{'io.modelcontextprotocol/protocolVersion'};

    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      result  => { content => [ { type => 'text', text => "spoke $version" } ] },
    } if defined $version && $self->{accepts}{$version};

    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      error   => {
        code    => -32022,
        message => 'Unsupported protocol version',
        data    => { supported => $self->{supported} },
      },
    };
  }
}

# The refusal names a revision this client can speak, so the request is sent
# again with it rather than handed back to the caller as a failure.
{
  my $server = Test::VersionServer->new(
    accepts   => { $spoken => 1 },
    supported => [ $spoken ],
  );
  my $client = Net::Async::MCP->new(
    server           => $server,
    protocol_version => '2024-11-05',
  );
  $loop->add($client);

  my $result = $client->call_tool('echo', { message => 'hi' })->get;
  is($result->{content}[0]{text}, "spoke $spoken",
    'a refused protocol version is renegotiated and the caller sees the result');

  my @calls = @{ $server->requests };
  is(scalar @calls, 2, 'which took exactly one retry');

  my $key = 'io.modelcontextprotocol/protocolVersion';
  is($calls[0]{params}{_meta}{$key}, '2024-11-05',
    'the first attempt carried the version the client was configured with');
  is($calls[1]{params}{_meta}{$key}, $spoken,
    'and the retry the one just agreed on, not the refused one again');
  is($calls[1]{params}{arguments}, { message => 'hi' },
    'otherwise repeating the original request');

  is($client->protocol_version, $spoken,
    'the agreed version is kept on the client');

  # Kept, not rediscovered: a version renegotiated per request would pay for
  # the refusal again on every single one of them.
  $client->read_resource('file:///one')->get;
  is(scalar @{ $server->requests }, 3, 'so a later request is not renegotiated again');
  is($server->requests->[2]{params}{_meta}{$key}, $spoken,
    'it goes out with the agreed version straight away');
}

# A server that refuses the very version it offered has a problem of its own,
# and one this client cannot fix by asking a third time. Note that with a
# single usable revision the guard against retrying the version already being
# spoken would stop this too - both agree that the second refusal is final.
{
  my $server = Test::VersionServer->new(
    accepts   => {},
    supported => [ $spoken ],
  );
  my $client = Net::Async::MCP->new(
    server           => $server,
    protocol_version => '2024-11-05',
  );
  $loop->add($client);

  my $f = $client->call_tool('echo', { message => 'hi' });
  ok($f->failure, 'a second refusal after the switch reaches the caller');
  like($f->failure, qr/-32022/, 'as the error the server sent');
  is(scalar @{ $server->requests }, 2,
    'and the request is retried exactly once, never in a loop');
}

# None of the offered revisions is one this client speaks, so there is nothing
# to retry with. What the caller gets then has to be the server's own error,
# because everything it could act on - the code, and the versions it would
# accept - is in there and in nothing this client could write instead. A
# revision only some dependency knows about ends up here too: the list a
# refusal is answered from is the client's own, not the installed server
# library's.
{
  my $server = Test::VersionServer->new(
    accepts   => {},
    supported => [ '1999-01-01' ],
  );
  my $client = Net::Async::MCP->new(
    server           => $server,
    protocol_version => '2024-11-05',
  );
  $loop->add($client);

  my $f = $client->call_tool('echo', { message => 'hi' });
  my ( $message, $category, $error ) = $f->failure;
  is($message, 'MCP error -32022: Unsupported protocol version',
    'an unusable offer leaves the server error unchanged');
  is($category, 'mcp', 'still categorised as the server error it is');
  is($error->{data}{supported}, ['1999-01-01'],
    'and still carrying the versions the server named');

  is(scalar @{ $server->requests }, 1, 'nothing was retried');
  is($client->protocol_version, '2024-11-05',
    'and the client kept the version it was configured with');
}

# The two retries this client knows about, meeting on one request: a server
# that first asks for input, then refuses the revision the answer came back in,
# and only then answers. What the renegotiated attempt carries has to be the
# round trip as it stands - the version just agreed on and the answer already
# given - and not the request as it was first made.
{
  package Test::MixedServer;
  sub new {
    my ( $class, %args ) = @_;
    return bless { %args, requests => [], answered => 0 }, $class;
  }
  sub requests { $_[0]{requests} }
  sub handle {
    my ( $self, $request ) = @_;
    push @{ $self->{requests} }, $request;
    return undef unless defined $request->{id};

    my %response = ( jsonrpc => '2.0', id => $request->{id} );
    my $nth      = ++$self->{answered};

    return { %response, result => {
      resultType    => 'input_required',
      requestState  => 'STATE-1',
      inputRequests => { confirm => { method => 'elicitation/create', params => {} } },
    } } if $nth == 1;

    return { %response, error => {
      code    => -32022,
      message => 'Unsupported protocol version',
      data    => { supported => $self->{supported} },
    } } if $nth == 2;

    return { %response, result => { content => [ { type => 'text', text => 'done' } ] } };
  }
}

{
  my $server = Test::MixedServer->new(supported => [ $spoken ]);
  my $asked  = 0;
  my $client = Net::Async::MCP->new(
    server              => $server,
    protocol_version    => '2024-11-05',
    client_capabilities => { elicitation => {} },
    on_input_request    => sub { $asked++; return { action => 'accept' } },
  );
  $loop->add($client);

  my $result = $client->call_tool('confirm_me', {})->get;
  is($result->{content}[0]{text}, 'done',
    'an input_required round and a renegotiation on one request still end in the result');
  is(scalar @{ $server->requests }, 3, 'in three attempts, one for each');

  my $last = $server->requests->[2]{params};
  is($last->{_meta}{'io.modelcontextprotocol/protocolVersion'}, $spoken,
    'the renegotiated attempt carries the version just agreed on');
  is($last->{inputResponses}{confirm}, { action => 'accept' },
    'and the answer that was already given');
  is($last->{requestState}, 'STATE-1', 'with the state that answer belongs to');
  is($asked, 1, 'so the handler is not troubled a second time for the same question');
}

# What a client does with an on_notification of its own can only be seen on a
# transport that delivers notifications, and that is the HTTP one - which needs
# Net::Async::HTTP, a recommendation of this distribution rather than a
# requirement. No request goes out for any of this; only the client side of the
# handler is under test.
if ( eval { require Net::Async::HTTP; 1 } ) {

  # on_notification is invoked by the transport, which would call a handler
  # handed over as it stands with the transport as its first argument, while
  # on_input_request - same client, same public API - is called with the
  # client. Invoking the event is exactly what an arriving notification does,
  # so nothing has to arrive to see which object the handler is called with.
  {
    my @seen;
    my $client = Net::Async::MCP->new(
      url             => 'http://mcp.invalid/mcp',
      on_notification => sub { push @seen, [ @_ ] },
    );
    $loop->add($client);

    my $notification = { method => 'notifications/progress', params => { progress => 1 } };
    $client->{transport}->maybe_invoke_event(on_notification => $notification);

    is(scalar @seen, 1, 'a handler set on the client is called for a notification');
    is($seen[0][0], exact_ref($client),
      'with the client as first argument, like every other event of this client');
    is($seen[0][1], $notification, 'and the notification as it arrived');
  }

  # Whatever reaches the transport's event slot is held by the transport, which
  # the client holds in turn, so a handler holding the client strongly would
  # keep both alive for as long as the process runs.
  {
    my $client = Net::Async::MCP->new(
      url             => 'http://mcp.invalid/mcp',
      on_notification => sub { },
    );
    $loop->add($client);

    # Deliberately kept: the transport outliving this scope is what makes the
    # question sharp, since it is the transport that holds the handler.
    my $transport = $client->{transport};

    weaken( my $weak_client = $client );
    $loop->remove($client);
    undef $client;

    is($weak_client, undef,
      'a client with an on_notification is still freed once the loop lets go of it');
  }
}
else {
  note 'Net::Async::HTTP is not installed, skipping the on_notification checks';
}

# Cancelling a request on the path a real caller takes. t/20_stdio.t cancels
# the future transport->send_request returned, but every client method goes
# through _request, which wraps that future in one of its own (followed_by) -
# the future a caller holds is not the one the transport is waiting on, and a
# cancel has to travel the whole chain back to it. That travel is what this
# block pins: cancelling the client future must reach the transport, drop its
# pending entry and fire its on_cancel. Which transport is underneath does not
# matter - Stdio answers on_cancel by writing notifications/cancelled, HTTP by
# closing the response stream - so the client is given a stand-in that tracks
# its requests exactly like the real ones do: a pending table, and an on_cancel
# that clears the entry.
{
  package Test::PendingTransport;
  sub new {
    my ( $class ) = @_;
    return bless { pending => {}, next_id => 0 }, $class;
  }
  sub send_request {
    # %options: binding hints from the client, none of which apply here
    my ( $self, $method, $params, %options ) = @_;

    my $id = ++$self->{next_id};
    my $future = Future->new;
    $self->{pending}{$id} = $future;
    $future->on_cancel(sub {
      delete $self->{pending}{$id};
      $self->{cancelled}++;
    });
    return $future;
  }
  sub mirrors_header_params { 0 }
}

{
  my $client = Net::Async::MCP->new(server => $server);
  $loop->add($client);

  # The transport is not what is under test, so it is swapped for the stand-in
  # above, which has the pending table and on_cancel of the real ones without
  # needing a subprocess or a remote server.
  my $transport = Test::PendingTransport->new;
  $client->{transport} = $transport;

  my $f = $client->call_tool('echo', { message => 'never answered' });
  is(scalar keys %{ $transport->{pending} }, 1,
    'the request is tracked in the transport while the call is in flight');

  $f->cancel;
  ok($f->is_cancelled, 'the caller future is cancelled');
  is(scalar keys %{ $transport->{pending} }, 0,
    'cancelling the client future drops the transport pending entry');
  is($transport->{cancelled}, 1,
    'and fires the transport on_cancel, so the request really is cancelled');
}

done_testing;
