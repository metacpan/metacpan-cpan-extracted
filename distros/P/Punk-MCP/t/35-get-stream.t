#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPSess;
use PMCPFakeStream;

my $t = sess_app('');
my ($sid) = init_session($t);

sub rpc { my ($method, $params, $s) = @_; (send_msg($t, { jsonrpc => '2.0', id => 7,
    method => $method, params => $params }, sid => $s // $sid))[1] }
sub get_stream {
    my (%o) = @_;
    my %h = (Accept => $o{accept} // 'text/event-stream');
    $h{'Mcp-Session-Id'} = $o{sid} if defined $o{sid};
    $h{Origin} = $o{origin} if $o{origin};
    $t->get_ok('/mcp', headers => \%h, env => $o{env} || {});
    return $t->status;
}

# ---- refusals before the stream ---------------------------------------------------

is(get_stream(), 400, 'GET with no session id is 400');
is(get_stream(sid => 'C' x 22), 404, 'an unknown session is 404');
my ($alice) = init_session($t, auth => 'Bearer alice');
$t->get_ok('/mcp', headers => { Accept => 'text/event-stream', 'Mcp-Session-Id' => $alice,
                              Authorization => 'Bearer mallory' });
is($t->status, 404, 'a session made with another credential is 404');
is(get_stream(sid => $sid, accept => 'application/json'), 406,
    'Accept without text/event-stream is 406');
is(get_stream(sid => $sid, origin => 'http://evil.test',
              env => { HTTP_HOST => 'localhost' }), 403, 'a foreign Origin is 403');

# ---- the live route --------------------------------------------------------------------

is_deeply(rpc('resources/subscribe', { uri => 'books://7' })->{result}, {},
    'resources/subscribe answers {}');
is(rpc('resources/subscribe', { uri => 'nope://x' })->{error}{code}, -32002,
    'subscribing to nothing is -32002');
is(rpc('resources/subscribe', { uri => 'vault://secret' })->{error}{code}, -32002,
    'and so is subscribing to what a guard hides');

{
    local $Punk::Plugin::MCP::_TEST_GET_HOOK = sub {
        my ($c, $stream, $s) = @_;
        $c->mcp_resource_updated('books://7');         # subscribed
        $c->mcp_resource_updated('books://8');         # not
        Punk::Plugin::MCP->resource_updated($PMCPSess::LAST, 'books://7');
        $stream->close;
    };
    $t->sse_ok('/mcp', headers => { 'Mcp-Session-Id' => $sid, Accept => 'text/event-stream' });
}
my @ev = @{ $t->sse_events };
is(scalar @ev, 2, 'two events: the request helper and the class method, both for books://7');
is_deeply(JSON::PP->new->decode($ev[0]{data}),
    { jsonrpc => '2.0', method => 'notifications/resources/updated',
      params => { uri => 'books://7' } }, 'notifications/resources/updated');
is($ev[0]{event}, 'message', 'as a message event');
is(Punk::Plugin::MCP::_stream_count(), 0, 'and the closed stream leaves the table');

is_deeply(rpc('resources/unsubscribe', { uri => 'books://7' })->{result}, {},
    'resources/unsubscribe answers {}');
{
    local $Punk::Plugin::MCP::_TEST_GET_HOOK = sub {
        my ($c, $stream) = @_;
        $c->mcp_resource_updated('books://7');
        $stream->close;
    };
    $t->sse_ok('/mcp', headers => { 'Mcp-Session-Id' => $sid, Accept => 'text/event-stream' });
}
is(scalar @{ $t->sse_events }, 0, 'after unsubscribe it is not sent');

# ---- without sessions -------------------------------------------------------------------

my $s0 = sess_app(q{session => 0}, store => '');
$s0->get_ok('/mcp', headers => { Accept => 'text/event-stream' });
is($s0->status, 405, 'session => 0: GET is 405');
my (undef, $r) = send_msg($s0, { jsonrpc => '2.0', id => 1, method => 'resources/subscribe',
                                 params => { uri => 'books://7' } });
is($r->{error}{code}, -32601, 'and resources/subscribe does not exist');
(undef, $r) = send_msg($s0, { jsonrpc => '2.0', id => 1, method => 'initialize',
                              params => { protocolVersion => '2025-11-25' } });
ok(!exists $r->{result}{capabilities}{resources}{subscribe}, 'nor is it advertised');

my ($cap) = init_session($t);
(undef, $r) = send_msg($t, { jsonrpc => '2.0', id => 1, method => 'initialize',
                             params => { protocolVersion => '2025-11-25' } });
ok($r->{result}{capabilities}{resources}{subscribe}, 'with sessions it is');

done_testing;
