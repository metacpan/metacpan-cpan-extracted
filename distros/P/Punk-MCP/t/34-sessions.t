#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPSess;
use JSON::PP ();

sub call { my ($t, $sid, %o) = @_; send_msg($t, { jsonrpc => '2.0', id => 2, method => 'tools/call',
    params => { name => 'echo', arguments => $o{args} // { q => 'x' } } }, sid => $sid, %o) }

# ---- boot -----------------------------------------------------------------------

eval { sess_app('', store => '')->get_ok('/') };
like($@, qr/`session => 'mcp'` names a store that is not declared \(add cache mcp =>/,
    'a session store that is not declared croaks at boot, naming it');
eval { sess_app('', store => "cache mcp => { backend => 'memory' };")->get_ok('/') };
like($@, qr/the session store 'mcp' is not shared across workers/,
    'a per-worker store croaks at boot');

# ---- initialize ----------------------------------------------------------------------

my $t = sess_app('');
my ($sid, $s, $r) = init_session($t);
is($s, 200, 'initialize is 200');
like($sid, qr/\A[A-Za-z0-9_-]{22}\z/, 'with an Mcp-Session-Id of 22 base64url characters');
ok($r->{result}{capabilities}{logging}, 'and, with a session, logging is advertised');
my ($sid2) = init_session($t);
isnt($sid2, $sid, 'a second initialize is a second session');

($s, $r) = send_msg($t, '{"jsonrpc":"2.0","id":1,"method":"initialize","params":"x"}');
is($r->{error}{code}, -32602, 'an initialize that fails');
ok(!defined $t->header('Mcp-Session-Id'), 'makes no session');

($s, $r) = send_msg($t, { jsonrpc => '2.0', id => 3, method => 'initialize',
                          params => { protocolVersion => '2025-11-25' } }, sid => $sid);
is($r->{error}{code}, -32600, 'initialize again inside a session is -32600');
ok(!defined $t->header('Mcp-Session-Id'), 'and hands out no new id');

# ---- every later request needs it -------------------------------------------------------

($s, $r) = call($t, undef);
is($s, 400, 'no session id is 400');
is($r->{error}{message}, 'a session id is required', 'saying why');
($s) = send_msg($t, { jsonrpc => '2.0', method => 'notifications/initialized' });
is($s, 400, 'a notification without one too');

for my $bad ('A' x 22, 'short', 'x' x 21 . '!', '') {
    ($s, $r) = call($t, $bad);
    is($s, 404, "an unknown or malformed id '$bad' is 404");
}
is($r->{error}{message}, 'unknown session', 'saying so');

($s, $r) = call($t, $sid);
is($s, 200, 'the session id works');
is($r->{result}{structuredContent}{q}, 'x', 'and the call is answered');
($s) = send_msg($t, { jsonrpc => '2.0', method => 'notifications/initialized' }, sid => $sid);
is($s, 202, 'a notification in the session is 202');

# ---- the version is the session's ------------------------------------------------------------

my ($old) = init_session($t, proto => '2025-06-18');
($s, $r) = call($t, $old, args => { q => [] });
($s, $r) = send_msg($t, { jsonrpc => '2.0', id => 4, method => 'tools/call',
    params => { name => 'echo', arguments => [] } }, sid => $old);
is($r->{error}{code}, -32602, 'no MCP-Protocol-Version: the session\'s 2025-06-18 is used');
($s, $r) = call($t, $old, version => '2025-11-25');
is($s, 400, 'a header naming another version than the session\'s is 400');
like($r->{error}{message}, qr/does not match the session/, 'saying so');
($s) = call($t, $old, version => '2025-06-18');
is($s, 200, 'the matching header is fine');

# ---- whose session ------------------------------------------------------------------------------

my ($alice) = init_session($t, auth => 'Bearer alice');
is((call($t, $alice, auth => 'Bearer alice'))[0], 200, 'the caller who made it can use it');
is((call($t, $alice, auth => 'Bearer mallory'))[0], 404, 'another credential cannot');
is((call($t, $alice))[0], 404, 'nor can no credential');

# ---- expiry and the slide -------------------------------------------------------------------------

$t = sess_app(q{session_ttl => 300});
{
    local $Punk::Plugin::MCP::_NOW = 1_000_000;
    ($sid) = init_session($t);
    $Punk::Plugin::MCP::_NOW += 250;
    is((call($t, $sid))[0], 200, 'used before it expires');
    $Punk::Plugin::MCP::_NOW += 250;
    is((call($t, $sid))[0], 200, 'and that use slid the expiry forward');
    $Punk::Plugin::MCP::_NOW += 301;
    is((call($t, $sid))[0], 404, 'unused past the ttl, it has expired');

    ($sid) = init_session($t);
    $Punk::Plugin::MCP::_NOW += 30;
    call($t, $sid);
    $Punk::Plugin::MCP::_NOW += 275;
    is((call($t, $sid))[0], 404,
        'a use within a minute of the last write does not slide (reads stay reads)');
}

# ---- one session's state is its own -----------------------------------------------------------------

$t = sess_app('');
my ($a1) = init_session($t);
my ($b1) = init_session($t);
send_msg($t, { jsonrpc => '2.0', id => 5, method => 'logging/setLevel',
               params => { level => 'error' } }, sid => $a1);
my (undef, undef, $body) = send_msg($t, { jsonrpc => '2.0', id => 6, method => 'tools/call',
    params => { name => 'logs' } }, sid => $a1);
like($body, qr/"result":\{"content":\[\{"text":"0,1"/, 'a level set in one session filters it');
(undef, undef, $body) = send_msg($t, { jsonrpc => '2.0', id => 6, method => 'tools/call',
    params => { name => 'logs' } }, sid => $b1);
like($body, qr/"text":"1,1"/, 'and not another');

# ---- cancellation is per session ------------------------------------------------------------

$t = sess_app('');
my ($sa) = init_session($t);
my ($sb) = init_session($t);
(undef, undef, $body) = send_msg($t, { jsonrpc => '2.0', id => 9, method => 'tools/call',
    params => { name => 'probe', arguments => { other => $sb } } }, sid => $sa);
my ($res) = $body =~ /^data: (\{"id":9.*)$/m;
$res = JSON::PP->new->decode($res)->{result}{structuredContent};
is($res->{session}, $sa, '$c->mcp->session names the session');
is($res->{after_other}, 0, 'a cancel for request 9 sent in another session does not touch it');
is($res->{after_own}, 1, 'one sent in its own session does');

# ---- stateless by default -------------------------------------------------------------------------

$t = sess_app(q{session => 0}, store => '');
($sid, $s) = init_session($t);
is($s, 200, 'session => 0: initialize');
ok(!defined $sid, 'hands out no session id');
is((call($t, undef))[0], 200, 'and needs none');

done_testing;
