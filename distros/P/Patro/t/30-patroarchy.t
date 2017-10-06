use Test::More;
#use Patro::Archy ':all', ':errno';
use strict;
use warnings;
use Time::HiRes qw(time sleep);

$SIG{ALRM} = sub {
    die "$0 test took too long. It's possible there was a deadlock";
};

if (!eval "use Patro::Archy ':all',':errno'; 1") {
    diag "# synchronization tests require threads and Patro::Archy";
    ok(1,"# synchronization tests require threads and Patro::Archy");
    done_testing;
    exit;
}

my $foo = {};
my $bar = [];

close STDERR;
open STDERR, '+>', \$STDERR;
(*STDERR)->autoflush(1);

alarm 20;
ok(plock($foo, "monitor-0"), 'lock');
ok(1 == punlock($foo, "monitor-0"), 'unlock');
my $s0 = $STDERR // '';
ok(!punlock($foo, "monitor-3"), 'unlock without possession fails');
ok($! == &FAIL_INVALID_WO_LOCK, 'errno set');
ok($s0 eq '' && $STDERR =~ /unlock called on .* without lock/,
   'warning written') or diag $STDERR;
ok(plock($foo, "monitor-1"), 'lock');
my $t = time;
ok(!plock($foo,"monitor-2",-1), 'non-blocking lock failed');
ok(time - $t < 0.5, 'non-blocking lock returned quickly');

$t = time;
my $s1 = $STDERR;
ok(!plock($foo,"monitor-2",2.5), 'timed lock failed');
my $s2 = $STDERR;
is(0+$!, &FAIL_EXPIRED, '... errno set');
ok($s1 eq $s2, '... without warning');
ok(time - $t > 1.5, 'timed lock took time');
ok(1 == punlock($foo,"monitor-1"), 'released resource');
ok(plock($foo,"monitor-2",-1), 'lock immediately accessible by new monitor');
ok(1 == punlock($foo,"monitor-2"), 'release reference from new monitor');


# stacked lock calls
alarm 20;
ok(plock($bar, "monitor-4"), 'got lock');
ok(plock($bar, "monitor-4"), 'stacked lock');
ok(plock($bar, "monitor-4"), 'stacked lock again');
ok(2 == punlock($bar, "monitor-4", 2), 'unlock with count');
$s1 = $STDERR;
ok(!plock($bar, "monitor-5", -1), 'lock not available for new monitor');
is(0+$!, &FAIL_EXPIRED, 'errno set');
ok($s1 eq $STDERR, '... without additional warning');
ok(1 == punlock($bar, "monitor-4",2), 'unlock with count too high ok');
ok($s1 ne $STDERR, '... but generates warning') or diag $STDERR;
ok(plock($bar, "monitor-5", -1), 'lock available after 2nd unlock');
ok(punlock($bar, "monitor-5"), 'lock released from new monitor');


sub tdiag { return; diag "# STEP ",@_; }

# simple wait/notify example
alarm 20;
if (CORE::fork() == 0) {
#    diag "wait/notify fork $$ launch";
    my $z = plock($bar, "child-4"); tdiag("1 - $z");
    sleep 3;
    $z = pwait($bar, "child-4"); tdiag("4 - $z");
    punlock($bar, "child-4"); tdiag(5);
    sleep 2;
    plock($bar, "child-6"); tdiag(6);
    pnotify($bar, "child-6"); tdiag(7);
    punlock($bar, "child-6"); tdiag(8);
#    diag "wait/notify fork $$ exit";
    exit;
}
sleep 1;
my $v;
$! = 0;
ok(!pwait($bar, "parent-5"),"wait fails without lock");
ok($! == &FAIL_INVALID_WO_LOCK, 'errno set');
$! = 0;
ok(!pnotify($bar, "parent-5"),"notify fails without lock");
ok($! == &FAIL_INVALID_WO_LOCK, 'errno set');

$t = time;

ok($v = plock($bar, "parent-5"), 'eventually got lock'); tdiag("2 - $v");
ok(time - $t > 1.5, '... but it took a while');

ok($v = pnotify($bar,"parent-5"), 'notify ok'); tdiag("3 - $v");
$t = time;
ok(pwait($bar,"parent-5"), 'wait ok'); tdiag(9);
ok(time - $t > 1.5, '... and wait we did');
ok(punlock($bar,"parent-5"), 'unlock ok'); tdiag(10);
CORE::wait;

# multi-notify semantics
alarm 20;
for my $monitor ("child-A", "child-B", "child-C") {
    if (CORE::fork() == 0) {
#	diag "multinotify $monitor $$ launch";
	plock($bar, $monitor);
	pwait($bar, $monitor);
	punlock($bar, $monitor);
#	diag "multinotify $monitor $$ exit";
	exit;
    }
}
sleep 3;
ok(plock($bar, "parent-6"), 'parent lock ok');
is(3, pnotify($bar, "parent-6", -1), 'notify all');

$v = pnotify($bar, "parent-6");
ok($v, 'starved pnotify returned true value');
ok($v==0, 'starved pnotify returned zero value');

ok(punlock($bar,"parent-6"), 'parent unlock ok');
CORE::wait for 1..3;

# steal semantics
alarm 20;
pipe RR,WW;
if (CORE::fork() == 0) {
#    diag "steal fork $$ launch";
    plock($bar, "child-E",2);
    print WW "\n"; close WW;
    sleep 5;
    punlock($bar, "child-E");
#    diag "steal fork $$ exit";
    exit;
}

scalar <RR>; close RR;
$t = time;
ok(!plock($bar, "parent-E", -1), 'lock not available');
ok(time - $t < 0.5, '... non-blocking lock');

$t = time;
ok(plock($bar, "parent-E", 3, 1), 'lock successfully acquired');
ok(time - $t > 2.5, '... after 3 seconds, probably stole it');
is(1, punlock($bar,"parent-E"), 'successfully unlocked');
CORE::wait;

	  



done_testing();
