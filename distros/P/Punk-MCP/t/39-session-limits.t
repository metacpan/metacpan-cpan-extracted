#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPSess;

local $Punk::Plugin::MCP::_NOW = 2_000_000;   # the start of a window

# ---- max_sessions -----------------------------------------------------------------

my $t = sess_app(q{max_sessions => 3, session_ttl => 100});
my @made = grep { defined } map { (init_session($t))[0] } 1 .. 3;
is(scalar @made, 3, 'three sessions under a cap of three');
my ($sid, $s, $r) = init_session($t);
is($s, 503, 'the fourth is 503');
ok(!defined $sid, 'with no session');
like($r->{error}{message}, qr/too many sessions/, 'saying why');
cmp_ok($t->header('Retry-After'), '>', 0, 'and when to try again');

send_msg($t, undef, sid => $made[0], http => 'DELETE');
is((init_session($t))[1], 503, 'DELETE does not hand a slot back (errs towards refusing)');

$Punk::Plugin::MCP::_NOW += 150;           # half way into the next window
is_deeply([map { (init_session($t))[1] } 1 .. 3], [200, 200, 503],
    'half way into the next window the last one counts for half: two more, not three');
$Punk::Plugin::MCP::_NOW += 60;            # 210: the earlier window is gone
is((init_session($t))[1], 200, 'once the old window has passed, sessions are made again');

# ---- per address ------------------------------------------------------------------------

$t = sess_app(q{max_sessions => 1000});
my %env1 = (env => { REMOTE_ADDR => '10.0.0.1' });
my @codes = map { (init_session($t, %env1))[1] } 1 .. 31;
is_deeply([@codes[0 .. 29]], [(200) x 30], 'thirty in a minute from one address');
is($codes[30], 429, 'the thirty-first is 429');
like($t->header('Retry-After'), qr/^\d+$/, 'with Retry-After');
is((init_session($t, env => { REMOTE_ADDR => '10.0.0.2' }))[1], 200, 'another address is fine');
$Punk::Plugin::MCP::_NOW += 60;
is((init_session($t, %env1))[1], 200, 'and the first again a minute later');

# only initialize is limited
my ($live) = init_session($t, env => { REMOTE_ADDR => '10.0.0.3' });
is((send_msg($t, { jsonrpc => '2.0', id => 1, method => 'ping' }, sid => $live, %env1))[0], 200,
    'requests in a session are not counted');

done_testing;
