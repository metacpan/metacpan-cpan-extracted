use strict;
use warnings;
use Test2::V0;

use Cwd qw( abs_path );
use File::Basename qw( dirname );
use Future;
use IO::Async::Loop;
use IO::Async::Process;
use IO::Socket::INET;
use JSON::MaybeXS;
use Net::Async::MCP;

# The legacy binding of the HTTP transport - sessions, the agreed
# MCP-Protocol-Version, requests the server sends on a response stream - against
# t/bin/legacy_http_server.pl, a real Streamable HTTP server shaped after the
# TypeScript SDK's that speaks nothing of the modern revision. It refuses a
# request outside a session with 400, one in an ended session with 404, one
# with the wrong MCP-Protocol-Version or with an Mcp-Method header with 400, and
# every request before notifications/initialized, so a client that gets any of
# that wrong fails here.

skip_all 'Net::Async::HTTP and HTTP::Message are required for the HTTP transport'
  unless eval { require Net::Async::HTTP; require HTTP::Request; 1 };

# Asked of a child perl rather than loaded here: the server runs in a
# subprocess of its own, and Mojolicious loads EV where it is installed, which
# takes SIGCHLD over from IO::Async.
skip_all 'Mojolicious is required for the legacy HTTP test server'
  unless system($^X, '-MMojolicious', '-e', '1') == 0;

# A client waiting for an answer that never comes hangs rather than fails.
alarm 120;

my $server_script = abs_path(dirname(__FILE__)) . '/bin/legacy_http_server.pl';
my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
my $loop = IO::Async::Loop->new;

my $control = Net::Async::HTTP->new;
$loop->add($control);

# Every server started, so that none outlives this file however it ends - a
# server left running holds this file's stderr open, and a harness waiting for
# it with it. The END block covers an ending this file sees; for a kill it
# never sees, each server is told this file's pid and exits once that is no
# longer its parent.
my @servers;
END { kill 'KILL', grep { defined } map { $_->pid } @servers }

# A server with its environment, up and listening.
sub start_server {
  my ( %env ) = @_;
  my $port   = $loop->new_future;
  my $buffer = '';
  my $process = IO::Async::Process->new(
    command => [ $^X, $server_script ],
    setup   => [ env => { %ENV, LEGACY_HTTP_PARENT => $$, %env } ],
    stdout  => {
      on_read => sub {
        my ( undef, $buffref ) = @_;
        $buffer .= $$buffref;
        $$buffref = '';
        $port->done($1) if !$port->is_ready && $buffer =~ /^(\d+)\n/;
        return 0;
      },
    },
    on_finish => sub { $port->fail('the test server exited') unless $port->is_ready },
  );
  $loop->add($process);
  push @servers, $process;
  my $base = 'http://127.0.0.1:' . $port->get;
  return { process => $process, base => $base, url => "$base/mcp" };
}

sub stop_server {
  my ( $server ) = @_;
  my $process = $server->{process};
  return unless $process->is_running;
  $process->kill('TERM');
  $process->finish_future->get;
}

# Every request the server received, in order.
sub server_log {
  my ( $server ) = @_;
  my $response = $control->GET("$server->{base}/control/log")->get;
  return $json->decode($response->content);
}

sub expire {
  my ( $server, %args ) = @_;
  my $uri = "$server->{base}/control/expire" . ( $args{sticky} ? "?sticky=$args{sticky}" : '' );
  $control->POST($uri, '', content_type => 'text/plain')->get;
}

# The JSON-RPC method of a logged POST, or the HTTP method of anything else.
sub what {
  my ( $entry ) = @_;
  return $entry->{method} ne 'POST' ? $entry->{method}
    : defined $entry->{body}{method} ? $entry->{body}{method}
    : 'response';
}

sub client {
  my ( $server, %args ) = @_;
  my $mcp = Net::Async::MCP->new(url => $server->{url}, %args);
  $loop->add($mcp);
  return $mcp;
}

sub tool_text { $_[0]->{content}[0]{text} }

# Waits until the server has logged a request matching $match, which is how a
# notification this client sends and nobody answers can be asserted.
sub wait_for_log {
  my ( $server, $match ) = @_;
  for (1 .. 50) {
    my ($found) = grep { $match->($_) } @{ server_log($server) };
    return $found if $found;
    $loop->delay_future(after => 0.1)->get;
  }
  return;
}

# The whole life of a legacy session, against a server that refuses the probe
# the way the TypeScript SDK does: 400 with a JSON-RPC -32000 body.
{
  my $server = start_server();
  my @notes;
  my $mcp = client($server,
    headers => {
      Authorization          => 'Bearer t0ken',
      'Mcp-Session-Id'       => 'forged',
      'MCP-Protocol-Version' => '1999-01-01',
    },
    on_notification => sub { push @notes, $_[1] },
  );

  $mcp->initialize->get;
  ok($mcp->is_legacy, 'a server refusing server/discover with 400 -32000 is legacy');
  is($mcp->protocol_version, '2025-11-25', 'on the newest revision both speak');
  is($mcp->server_info->{name}, 'LegacyHTTPServer', 'server_info from the InitializeResult');
  is($mcp->{transport}->session_id, 'session-1', 'the session id of the initialize answer is kept');

  is([ map { $_->{name} } @{ $mcp->list_tools->get } ], [qw( echo roots slow )],
    'requests are served in the session, so the whole handshake went through');

  is(tool_text($mcp->call_tool('echo', { message => 'hi' })->get), 'Echo: hi (ping {})',
    'a ping the server sends on the response stream is answered with {}');
  is([ map { $_->{method} } @notes ], ['notifications/message'],
    'a notification on that stream reaches on_notification');
  like(tool_text($mcp->call_tool('roots', {})->get), qr/-32601/,
    'any other request from the server is refused with -32601');

  # Legacy cancellation is a notification of its own, not a closed stream.
  my $slow = $mcp->call_tool('slow', {});
  my $call = wait_for_log($server, sub {
    what($_[0]) eq 'tools/call' && $_[0]{body}{params}{name} eq 'slow' });
  ok($call, 'the slow call reached the server');
  $slow->cancel;
  my $cancelled = wait_for_log($server, sub { what($_[0]) eq 'notifications/cancelled' });
  ok($cancelled, 'cancelling a request sends notifications/cancelled');
  is($cancelled->{body}{params}{requestId}, $call->{body}{id}, 'naming that request');
  is($cancelled->{headers}{'Mcp-Session-Id'}, 'session-1', 'in the session');

  my $log = server_log($server);
  my ( $probe, $initialize, @session ) = @$log;
  is(what($probe), 'server/discover', 'the client probed with server/discover first');
  is($probe->{headers}{'Mcp-Method'}, 'server/discover', 'as a modern request, headers and all');
  is(what($initialize), 'initialize', 'then fell back to initialize');
  ok(!exists $initialize->{headers}{'Mcp-Session-Id'}, 'which carries no session id');
  ok(!exists $initialize->{headers}{'MCP-Protocol-Version'}, 'and no protocol version yet');
  ok(!exists $initialize->{headers}{'Mcp-Method'}, 'and no modern routing header');
  is(what($session[0]), 'notifications/initialized', 'then notifications/initialized');

  is([ grep { ( $_->{headers}{'Mcp-Session-Id'} // '' ) ne 'session-1' } @session ], [],
    'every later POST carries the session id, not the one the caller configured');
  is([ grep { ( $_->{headers}{'MCP-Protocol-Version'} // '' ) ne '2025-11-25' } @session ], [],
    'and the agreed MCP-Protocol-Version');
  is([ grep { exists $_->{headers}{'Mcp-Method'} } @session ], [],
    'and no Mcp-Method');
  is([ grep { ( $_->{headers}{Authorization} // '' ) ne 'Bearer t0ken' } @$log ], [],
    'while a configured Authorization travels on every request of both eras');
  my @answers = grep { what($_) eq 'response' } @session;
  is([ map { $_->{body}{result} // $_->{body}{error}{code} } @answers ], [ {}, -32601 ],
    'the answers to the server requests were POSTed in the session');

  ok(lives { $mcp->shutdown->get }, 'shutdown ends the session') or note $@;
  my ($delete) = grep { $_->{method} eq 'DELETE' } @{ server_log($server) };
  ok($delete, 'with a DELETE');
  is($delete->{headers}{'Mcp-Session-Id'}, 'session-1', 'naming the session');
  is($delete->{headers}{'MCP-Protocol-Version'}, '2025-11-25', 'in the agreed revision');
  is($mcp->{transport}->session_id, undef, 'and the session is forgotten');

  $loop->remove($mcp);
  stop_server($server);
}

# The server ends the session: the next request is answered 404, and the
# client starts a new session and sends the request again in it.
{
  my $server = start_server();
  my $mcp = client($server);
  $mcp->initialize->get;

  expire($server);
  my $tools = $mcp->list_tools;
  ok(lives { $tools->get }, 'a request in an ended session succeeds in a new one')
    or note $tools->failure;
  is($mcp->{transport}->session_id, 'session-2', 'the new session is the one kept');

  my @log = map { what($_) . ' ' . ( $_->{headers}{'Mcp-Session-Id'} // '-' ) }
    @{ server_log($server) }[ 3 .. 6 ];
  is(\@log, [
    'tools/list session-1',
    'initialize -',
    'notifications/initialized session-2',
    'tools/list session-2',
  ], 'by a new handshake without the old session id, then the request once more');

  # Several requests running into the same ended session start one new
  # session between them.
  expire($server);
  my @calls = map { $mcp->list_tools } 1 .. 3;
  Future->wait_all(@calls)->get;
  is([ map { $_->is_done ? 'done' : scalar $_->failure } @calls ], [ ('done') x 3 ],
    'requests that all hit the ended session succeed');
  is(scalar( grep { what($_) eq 'initialize' } @{ server_log($server) } ), 3,
    'after one new handshake between them');

  $mcp->shutdown->get;
  $loop->remove($mcp);
  stop_server($server);
}

# A server that ends the new session as well is not one more session away from
# answering: the request fails, once.
{
  my $server = start_server();
  my $mcp = client($server);
  $mcp->initialize->get;

  expire($server, sticky => 1);
  my ( $message, $category, $session ) = $mcp->list_tools->failure;
  like($message, qr/^MCP tools\/list: the server ended the new session as well/,
    'a second 404 fails the request');
  is($category, 'mcp_session_expired', 'in the session category');
  is($session, 'session-2', 'naming the session that ended');
  is(scalar( grep { what($_) eq 'initialize' } @{ server_log($server) } ), 2,
    'after exactly one new handshake');

  $loop->remove($mcp);
  stop_server($server);
}

# A 405 to the DELETE is a server that does not let clients end sessions, and
# a close all the same; any other refusal is reported, not hidden.
{
  my $server = start_server(LEGACY_HTTP_DELETE => 405);
  my $mcp = client($server);
  $mcp->initialize->get;
  ok(lives { $mcp->shutdown->get }, 'a DELETE answered 405 still shuts down') or note $@;
  $loop->remove($mcp);
  stop_server($server);

  $server = start_server(LEGACY_HTTP_DELETE => 500);
  $mcp = client($server);
  $mcp->initialize->get;
  like(scalar $mcp->shutdown->failure,
    qr/^MCP HTTP session session-1 could not be ended: 500/,
    'a DELETE answered 500 fails the shutdown Future with the reason');
  is($mcp->{transport}->session_id, undef, 'and the session is forgotten all the same');
  $loop->remove($mcp);
  stop_server($server);
}

# Pinned to a legacy revision: straight to initialize, and the server's own
# revision agreed on.
{
  my $server = start_server(LEGACY_HTTP_VERSIONS => '2025-06-18,2025-03-26');
  my $mcp = client($server, protocol_version => '2025-03-26');
  $mcp->initialize->get;
  ok(lives { $mcp->list_tools->get }, 'a legacy pin works') or note $@;

  my $log = server_log($server);
  is(what($log->[0]), 'initialize', 'without a server/discover probe');
  is($log->[0]{body}{params}{protocolVersion}, '2025-03-26', 'asking for the pinned revision');
  is($log->[-1]{headers}{'MCP-Protocol-Version'}, '2025-03-26',
    'and sending it as MCP-Protocol-Version, which 2025-03-26 ignores and later ones need');

  $mcp->shutdown->get;
  $loop->remove($mcp);
  stop_server($server);
}

# A 400 with no body at all says nothing modern: legacy.
{
  my $server = start_server(LEGACY_HTTP_PREINIT => 'empty');
  my $mcp = client($server);
  $mcp->initialize->get;
  ok($mcp->is_legacy, 'a probe refused with an empty 400 falls back to initialize');
  $mcp->shutdown->get;
  $loop->remove($mcp);
  stop_server($server);
}

# A 400 carrying -32022 is a modern server, whatever the status: no fallback,
# even with nothing in its list this client speaks.
{
  my $server = start_server(LEGACY_HTTP_PREINIT => 'modern');
  my $mcp = client($server);
  my ( $message, $category, $error ) = $mcp->initialize->failure;
  is($category, 'mcp', 'a -32022 body fails initialize with the server error');
  is($error->{data}{supported}, ['2027-01-01'], 'carrying what the server named');
  is([ map { what($_) } @{ server_log($server) } ], ['server/discover'],
    'and no initialize was sent');
  ok(!$mcp->is_legacy, 'the client did not become legacy');
  $loop->remove($mcp);
  stop_server($server);
}

# A server that assigns no session: no session id anywhere, and nothing to
# DELETE.
{
  my $server = start_server(LEGACY_HTTP_SESSION => 0);
  my $mcp = client($server);
  $mcp->initialize->get;
  is($mcp->{transport}->session_id, undef, 'no session id where the server assigned none');
  ok(lives { $mcp->list_tools->get }, 'and requests are served without one') or note $@;
  $mcp->shutdown->get;
  is([ grep { $_->{method} eq 'DELETE' } @{ server_log($server) } ], [],
    'and shutting down sends no DELETE');
  $loop->remove($mcp);
  stop_server($server);
}

# Nobody listening: a connection that cannot be made is no answer from a
# legacy server, and initialize fails with it instead of trying a second
# handshake against the same closed port.
{
  my $socket = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
    or die "cannot find a free port: $!";
  my $port = $socket->sockport;
  close $socket;

  my $mcp = client({ url => "http://127.0.0.1:$port/mcp" });
  my @sent;
  no warnings 'redefine';
  my $send = \&Net::Async::MCP::Transport::HTTP::send_request;
  local *Net::Async::MCP::Transport::HTTP::send_request = sub { push @sent, $_[1]; goto &$send };

  my ( $message, $category ) = $mcp->initialize->failure;
  like($message, qr/Connection refused/, 'a refused connection fails initialize with it');
  is($category, 'connect', 'categorised as the connection failure it is, not a server answer');
  is(\@sent, ['server/discover'], 'without falling back to initialize');
  ok(!$mcp->is_legacy, 'and without becoming legacy');
  $loop->remove($mcp);
}

done_testing;
