use strict;
use warnings;
use Test2::V0;

use Cwd qw( abs_path realpath );
use File::Basename qw( dirname );
use File::Temp;
use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::MCP;
use Time::HiRes qw( time );

# The legacy era - the initialize handshake of revisions 2024-11-05 to
# 2025-11-25 - against t/bin/legacy_mcp_server.pl, a hand-rolled server that
# speaks nothing else: it refuses server/discover the way legacy servers do,
# and refuses every request until notifications/initialized has arrived, so a
# client that skips any part of the handshake fails here. It needs no part of
# MCP, so nothing in this file skips but the one block that pins a legacy
# revision against the Perl MCP::Server.
#
# A client that waits for an answer that never comes hangs rather than fails;
# the alarm turns that into a failure of this file.
alarm 120;

# Asked here, before the first subprocess, and not where it is needed at the
# end: loading MCP::Server loads Mojolicious, which loads EV where it is
# installed, and EV takes over SIGCHLD - after IO::Async has started watching
# children, no exit is ever reaped again and every later close hangs.
my $have_mcp = eval { require MCP::Server; 1 };

my $legacy_server = abs_path(dirname(__FILE__)) . '/bin/legacy_mcp_server.pl';
my $modern_server = abs_path(dirname(__FILE__)) . '/bin/test_mcp_server.pl';

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
my $loop = IO::Async::Loop->new;

my @LEGACY = ( '2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05' );

# A client of the legacy server, configured through its environment - which
# goes through the env option this file also tests on its own below.
sub legacy_client {
  my ( %args ) = @_;
  my $server_env = delete $args{server_env} // {};
  my $client = Net::Async::MCP->new(
    command => [ $^X, $legacy_server ],
    env     => $server_env,
    %args,
  );
  $loop->add($client);
  return $client;
}

# Every message the server has received so far, decoded. Asked of the
# transport directly with a method of the test server's own, which it answers
# at any point of the handshake.
sub transcript {
  my ( $client ) = @_;
  my $lines = $client->{transport}->send_request('test/transcript')->get->{lines};
  return [ map { $json->decode($_) } @$lines ];
}

sub methods { [ map { $_->{method} } grep { defined $_->{id} } @{ $_[0] } ] }

sub has_protocol_meta {
  my ( $message ) = @_;
  my $meta = ref $message->{params} eq 'HASH' ? $message->{params}{_meta} : undef;
  return ref $meta eq 'HASH' && grep { m{^io\.modelcontextprotocol/} } keys %$meta;
}

sub tool_text { $_[0]->{content}[0]{text} }

# The default: server/discover answered with -32601, as every legacy server
# answers a method it does not know. That is not a modern refusal, so the
# client falls back to initialize and speaks legacy from then on.
{
  my @notes;
  my $mcp = legacy_client(on_notification => sub { push @notes, $_[1] });

  my $result = $mcp->initialize->get;
  ok($mcp->is_legacy, 'a server refusing server/discover with -32601 is legacy');
  is($mcp->protocol_version, $LEGACY[0],
    'and the newest legacy revision is asked for and agreed on');
  is($result->{protocolVersion}, $LEGACY[0], 'initialize returns the InitializeResult');
  is($mcp->server_info, { name => 'LegacyServer', version => '1.0' },
    'server_info comes from serverInfo');
  is($mcp->server_capabilities, { tools => {} }, 'server_capabilities from capabilities');
  is($mcp->instructions, 'Use echo to echo.', 'instructions from instructions');

  # The server refuses tools/list until notifications/initialized arrived, so
  # a listing is proof the notification was sent.
  my $tools = $mcp->list_tools->get;
  is([ map { $_->{name} } @$tools ], [qw( ask_client crash echo whoami )],
    'requests after the handshake are served, so notifications/initialized was sent');

  my $echo = $mcp->call_tool('echo', { message => 'hi' })->get;
  is(tool_text($echo), 'Echo: hi', 'a legacy result without resultType is final');
  is([ map { $_->{method} } @notes ], ['notifications/message'],
    'a notification of a legacy server reaches on_notification');

  my $seen = transcript($mcp);
  is($seen->[0]{method}, 'server/discover', 'the client probed with server/discover first');
  is($seen->[0]{params}{_meta}{'io.modelcontextprotocol/protocolVersion'}, '2026-07-28',
    'carrying the modern revision it prefers');
  is($seen->[1]{method}, 'initialize', 'then fell back to initialize');
  is($seen->[1]{params}{protocolVersion}, $LEGACY[0], 'asking for the newest legacy revision');
  is($seen->[1]{params}{capabilities}, {}, 'declaring no client capabilities');
  is($seen->[1]{params}{clientInfo}{name}, 'Net::Async::MCP', 'and naming the client');
  is($seen->[2], { jsonrpc => '2.0', method => 'notifications/initialized' },
    'followed by notifications/initialized');

  my @legacy_requests = @{$seen}[ 1 .. $#$seen ];
  ok(!( grep { has_protocol_meta($_) } @legacy_requests ),
    'no request after the probe carries io.modelcontextprotocol/* keys in _meta');

  my $listen = $mcp->subscriptions_listen({ toolsListChanged => 1 });
  like($listen->failure,
    qr/^MCP subscriptions\/listen needs protocol revision 2026-07-28; this server speaks legacy revision 2025-11-25/,
    'subscriptions_listen fails on a legacy connection, saying why');
  is(scalar grep({ ( $_->{method} // '' ) eq 'subscriptions/listen' } @{ transcript($mcp) }), 0,
    'and sends nothing');

  ok($mcp->shutdown->get, 'a legacy connection shuts down');
  $loop->remove($mcp);
}

# A legacy server may ask its client for a ping at any time, and every
# revision requires the client to answer it. What this client does not serve
# is refused with -32601 rather than left unanswered.
{
  my $mcp = legacy_client();
  $mcp->initialize->get;

  my $ping = $json->decode(tool_text($mcp->call_tool('ask_client', { method => 'ping' })->get));
  is($ping, { result => {} }, 'a ping from a legacy server is answered with {}');

  my $roots = $json->decode(tool_text($mcp->call_tool('ask_client', { method => 'roots/list' })->get));
  is($roots->{error}{code}, -32601, 'any other request is refused with -32601');

  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# A legacy server that does not answer server/discover at all. Nothing tells
# it apart from a slow modern one but time, so the probe gives up after
# discover_timeout and the client falls back.
{
  my $mcp = legacy_client(
    discover_timeout => 0.5,
    server_env       => { LEGACY_MCP_DISCOVER => 'silent' },
  );

  my $started = time;
  $mcp->initialize->get;
  ok($mcp->is_legacy, 'a silent probe falls back to initialize');
  ok(time - $started < 5, 'after discover_timeout rather than any default');
  is(methods(transcript($mcp)), [ 'server/discover', 'initialize', 'test/transcript' ],
    'one probe, then the handshake');

  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# The same, but the server answers the probe after all - once the fallback has
# begun. That answer must land on nothing: the era is decided.
{
  my $mcp = legacy_client(
    discover_timeout => 0.5,
    server_env       => { LEGACY_MCP_DISCOVER => 'late' },
  );

  $mcp->initialize->get;
  ok($mcp->is_legacy, 'a probe answered after the fallback began does not undo it');
  is($mcp->protocol_version, $LEGACY[0], 'the agreed revision is the legacy one');
  ok(lives { $mcp->list_tools->get }, 'and the connection keeps working') or note $@;

  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# A server that speaks an older legacy revision answers initialize with it, and
# that is the revision the connection uses.
{
  my $mcp = legacy_client(server_env => { LEGACY_MCP_VERSIONS => '2025-03-26' });
  $mcp->initialize->get;
  is($mcp->protocol_version, '2025-03-26', 'an older legacy revision is accepted');
  ok(lives { $mcp->list_tools->get }, 'and served') or note $@;
  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# A server answering with a revision this client does not speak. The
# specification leaves one thing to do, stop, and the failure has to say what
# the server offered and what this client could have taken.
{
  my $mcp = legacy_client(server_env => { LEGACY_MCP_VERSIONS => '2099-01-01' });

  my $f = $mcp->initialize;
  my $expected = "MCP server answered initialize with protocol version '2099-01-01', "
    . 'which this client does not speak (it speaks ' . join(', ', @LEGACY)
    . ' over initialize)';
  like(scalar $f->failure, qr/^\Q$expected\E/,
    'an unspoken revision fails the handshake, naming both sides');
  ok(!$mcp->is_legacy, 'the client is not left half in the legacy era');
  is(methods(transcript($mcp)), [ 'server/discover', 'initialize', 'test/transcript' ],
    'and no notifications/initialized follows');
  ok($mcp->shutdown->get, 'the transport is left to be shut down');
  $loop->remove($mcp);
}

# Pinned to a legacy revision: no probe, straight to initialize.
{
  my $mcp = legacy_client(protocol_version => '2025-06-18');
  $mcp->initialize->get;
  ok($mcp->is_legacy, 'a legacy pin speaks legacy');
  is($mcp->protocol_version, '2025-06-18', 'in the pinned revision');

  my $seen = transcript($mcp);
  is($seen->[0]{method}, 'initialize', 'with no server/discover probe first');
  is($seen->[0]{params}{protocolVersion}, '2025-06-18', 'asking for the pinned revision');

  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# Pinned to the modern revision: strict, so a legacy server's refusal is the
# answer and nothing falls back.
{
  my $mcp = legacy_client(protocol_version => '2026-07-28');
  my $f = $mcp->initialize;
  my ( $message, $category, $error ) = $f->failure;
  like($message, qr/^MCP error -32601/, 'a modern pin fails against a legacy server');
  is($category, 'mcp', 'with the server error itself');
  ok(!$mcp->is_legacy, 'and does not become legacy');
  is(methods(transcript($mcp)), [ 'server/discover', 'test/transcript' ],
    'no initialize was sent');
  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# A server refusing the probe with -32022 is modern, and the specification
# rules out falling back - but where the versions it names are legacy ones,
# using one of them is doing what it asks.
{
  my $mcp = legacy_client(server_env => {
    LEGACY_MCP_DISCOVER => 'unsupported',
    LEGACY_MCP_VERSIONS => '2025-03-26,2025-06-18',
  });
  $mcp->initialize->get;
  ok($mcp->is_legacy, 'a -32022 offering only legacy revisions leads to initialize');
  is($mcp->protocol_version, '2025-06-18',
    'asking for the newest of them this client speaks, whatever the order offered');
  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# The same refusal naming nothing this client speaks: modern, unusable, and no
# fallback either.
{
  my $mcp = legacy_client(server_env => {
    LEGACY_MCP_DISCOVER => 'unsupported',
    LEGACY_MCP_VERSIONS => '1999-01-01',
  });
  my ( $message, $category, $error ) = $mcp->initialize->failure;
  is($message, 'MCP error -32022: Unsupported protocol version',
    'a -32022 naming nothing usable fails with the server error');
  is($error->{data}{supported}, ['1999-01-01'], 'carrying the versions it named');
  is(methods(transcript($mcp)), [ 'server/discover', 'test/transcript' ],
    'and no initialize was sent');
  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# env and cwd describe the subprocess: a value sets a variable, undef removes
# an inherited one, the rest of %ENV is inherited, and the process starts in
# cwd.
{
  my $dir = File::Temp->newdir;
  local $ENV{NAMCP_TEST_DROP} = 'inherited';
  local $ENV{NAMCP_TEST_KEEP} = 'kept';

  my $mcp = legacy_client(
    server_env => { NAMCP_TEST_SET => 'set here', NAMCP_TEST_DROP => undef },
    cwd        => "$dir",
  );
  $mcp->initialize->get;

  my $who = $json->decode(tool_text($mcp->call_tool('whoami',
    { vars => [qw( NAMCP_TEST_SET NAMCP_TEST_DROP NAMCP_TEST_KEEP )] })->get));
  is($who->{env}, {
    NAMCP_TEST_SET  => 'set here',
    NAMCP_TEST_DROP => undef,
    NAMCP_TEST_KEEP => 'kept',
  }, 'env sets, removes with undef, and leaves the rest of %ENV inherited');
  is(realpath($who->{cwd}), realpath("$dir"), 'cwd is where the subprocess starts');

  $mcp->shutdown->get;
  $loop->remove($mcp);
}

# Stderr is the server's log: every line reaches on_stderr, called with the
# client, and the last 20 are what a request the process leaves unanswered
# fails with, next to the exit code.
{
  my @lines;
  my $mcp = legacy_client(on_stderr => sub { push @lines, [@_] });
  $mcp->initialize->get;

  my $f = $mcp->call_tool('crash', {});
  my $failure = $f->failure;
  like($failure, qr/^MCP server process exited \(code 3\); stderr: crash line 6 \| /,
    'a request the process left unanswered fails with its exit code and stderr');
  like($failure, qr/ \| crash line 25\b/, 'down to the last line it wrote');
  unlike($failure, qr/crash line 5 /, 'but no further back than 20 lines');
  is([ $mcp->{transport}->stderr_tail ], [ map { "crash line $_" } 6 .. 25 ],
    'which is what stderr_tail keeps');

  is($lines[0][0], exact_ref($mcp), 'on_stderr is called with the client');
  is([ map { $_->[1] } @lines ],
    [ 'legacy test server starting', map { "crash line $_" } 1 .. 25 ],
    'once per line, all of them, without line endings');

  like($mcp->call_tool('echo', {})->failure, qr/^MCP server process exited \(code 3\); stderr: /,
    'a request sent after the exit fails the same way');
  $loop->remove($mcp);
}

# A command that cannot be executed fails the handshake with the reason
# instead of leaving it waiting for an answer, and so does a missing cwd.
{
  my $mcp = Net::Async::MCP->new(command => ['/nonexistent/mcp-server']);
  $loop->add($mcp);
  like(scalar $mcp->initialize->failure,
    qr{^MCP server failed to start: cannot run /nonexistent/mcp-server: \S},
    'an unrunnable command fails initialize with the reason');
  $loop->remove($mcp);

  my $nowhere = Net::Async::MCP->new(
    command => [ $^X, $legacy_server ],
    cwd     => '/nonexistent/dir',
  );
  ok(lives { $loop->add($nowhere) }, 'a missing cwd does not die joining the loop')
    or note $@;
  like(scalar $nowhere->initialize->failure,
    qr/^\QMCP server failed to start: cannot run $^X: no such working directory '\/nonexistent\/dir'\E/,
    'and fails initialize with the reason instead');
  $loop->remove($nowhere);
}

# Shutting down follows the stdio binding: stdin is closed first, and a server
# that exits on the end of its input is never signalled - its exit is a plain
# exit 0, where a SIGTERM up front would have ended it by signal.
{
  my $mcp = Net::Async::MCP->new(command => [ $^X, '-e', '1 while <STDIN>; exit 0' ]);
  $loop->add($mcp);
  $mcp->shutdown->get;
  is(scalar $mcp->{transport}->send_request('ping')->failure,
    'MCP server process exited (code 0)',
    'a server that exits on the end of its stdin is not signalled');
  $loop->remove($mcp);
}

# One that ignores both its stdin and SIGTERM still goes: SIGKILL after the
# two grace periods.
{
  my $mcp = Net::Async::MCP->new(
    command => [ $^X, '-e', '$SIG{TERM} = "IGNORE"; sleep 1 while 1' ],
  );
  $loop->add($mcp);
  my $started = time;
  $mcp->shutdown->get;
  is(scalar $mcp->{transport}->send_request('ping')->failure,
    'MCP server process exited (signal 9)',
    'a server ignoring stdin and SIGTERM is killed');
  ok(time - $started >= 3.5, 'only after both grace periods');
  $loop->remove($mcp);
}

# The Perl MCP::Server answers the legacy handshake too (MCP::Server::Legacy),
# so a client pinned to a legacy revision reaches it that way - and one that
# is not pinned keeps finding it modern, which t/20_stdio.t covers.
SKIP: {
  skip 'MCP is required for the MCP::Server legacy pin', 5 unless $have_mcp;

  my $mcp = Net::Async::MCP->new(
    command          => [ $^X, $modern_server ],
    protocol_version => '2025-06-18',
  );
  $loop->add($mcp);

  $mcp->initialize->get;
  ok($mcp->is_legacy, 'a legacy pin speaks legacy to MCP::Server');
  is($mcp->protocol_version, '2025-06-18', 'which agrees on the pinned revision');
  is($mcp->server_info->{name}, 'TestServer', 'and names itself in serverInfo');
  is(scalar @{ $mcp->list_tools->get }, 2, 'lists its tools');
  is(tool_text($mcp->call_tool('add', { a => 10, b => 20 })->get), '30', 'and calls them');

  $mcp->shutdown->get;
  $loop->remove($mcp);
}

done_testing;
