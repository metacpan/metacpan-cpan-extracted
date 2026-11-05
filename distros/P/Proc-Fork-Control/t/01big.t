use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(time);

# Proc::Fork::Control enables warnings. This file records every warning
# from the parent and from children, and fails if that record is not empty.
my ($dir, $warnfile);
BEGIN {
    $dir = tempdir('pfc-XXXX', TMPDIR => 1, CLEANUP => 1);
    $warnfile = "$dir/warnings";
    open my $fh, '>', $warnfile or die "open $warnfile: $!";
    close $fh;

    $SIG{__WARN__} = sub {
        my ($msg) = @_;
        local $SIG{__WARN__};
        if (open my $out, '>>', $warnfile) {
            print {$out} $msg;
            close $out;
        }
        print STDERR $msg;
    };
}

BEGIN {
    use_ok('Proc::Fork::Control') || BAIL_OUT('Cannot load Proc::Fork::Control');
}

END {
    if (defined &cfork_kill_children) {
        cfork_nonblocking(0);
        cfork_kill_children('KILL');
        eval { cfork_wait(1) };
    }
}

alarm(45);
local $SIG{ALRM} = sub { die "functional tests exceeded 45s\n" };

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh;
    return defined $text ? $text : '';
}

sub fresh {
    my ($max) = @_;
    cfork_nonblocking(0);
    cfork_kill_children('TERM');
    cfork_wait(2);
    return cfork_init($max);
}

is($Proc::Fork::Control::VERSION, '1.7', 'version is 1.7');

# Nonblocking cfork returns while the child is still running.
fresh(4);
cfork_nonblocking(1);
my $ran = "$dir/ran";
my $pid = cfork(sub {
    cfork_usleep(800000);
    open my $fh, '>', $ran or exit 98;
    print {$fh} "ran\n";
    close $fh;
    cfork_exit(0);
});
ok(defined $pid && $pid > 0, 'cfork returns a child pid');
is(cfork_is_child(), 0, 'parent is not a child');
is(cfork_active_children(), 1, 'one active child');
is(cfork_has_children(), 1, 'parent has children');
is_deeply([sort { $a <=> $b } cfork_list_children()], [$pid], 'list children');
my %kids = cfork_list_children(1);
ok(exists $kids{$pid}, 'list children as a hash');
my $dob = cfork_child_dob($pid);
cmp_ok($dob, '>', 0, 'child dob is an epoch');
cmp_ok($dob, '<=', time() + 1, 'child dob is not in the future');
ok(!-e $ran, 'cfork returned before the child finished');
cfork_nonblocking(0);
ok(cfork_wait(), 'blocking wait reaps the child');
is(slurp($ran), "ran\n", 'child body ran');
is(cfork_active_children(), 0, 'no active children after wait');
is(cfork_has_children(), 0, 'has_children is clear after wait');
ok(!defined cfork_child_dob($pid), 'dob is forgotten after reap');

# The cap blocks a second cfork until a slot is free, even in nonblocking mode.
fresh(1);
cfork_nonblocking(1);
my $t0 = time();
my $first = cfork(sub { cfork_usleep(300000); cfork_exit(0); });
ok(defined $first && $first > 0, 'first child under the cap');
my $second = cfork(sub { cfork_exit(0); });
my $elapsed = time() - $t0;
ok(defined $second && $second > 0, 'second child started after a slot freed');
cmp_ok($elapsed, '>=', 0.2, 'second cfork waited for the cap');
cmp_ok($elapsed, '<', 2, 'second cfork did not stall');
cfork_nonblocking(0);
ok(cfork_wait(), 'reap cap test');

# Re-init while a child is alive keeps that pid and raises the cap.
fresh(1);
cfork_nonblocking(1);
my $kept = cfork(sub { cfork_usleep(800000); cfork_exit(0); });
ok(defined $kept && $kept > 0, 'child to keep across re-init');
ok(cfork_init(2), 're-init while a child is alive');
is_deeply([sort { $a <=> $b } cfork_list_children()], [$kept], 'live pid kept');
$t0 = time();
my $extra = cfork(sub { cfork_exit(0); });
$elapsed = time() - $t0;
ok(defined $extra && $extra > 0, 'extra child after the cap was raised');
cmp_ok($elapsed, '<', 0.75, 'raised cap did not block');
cfork_nonblocking(0);
ok(cfork_wait(2), 'reap re-init test');

# A child does not inherit the parent's pid list.
fresh(4);
cfork_nonblocking(1);
my $sib = cfork(sub { cfork_usleep(800000); cfork_exit(0); });
ok(defined $sib && $sib > 0, 'sibling started');
my $report = "$dir/isolate";
my $child = cfork(sub {
    open my $fh, '>', $report or exit 98;
    print {$fh} cfork_is_child() ? "child\n" : "parent\n";
    print {$fh} cfork_has_children() ? "has\n" : "nohas\n";
    print {$fh} 'pids:' . join(',', cfork_list_children()) . "\n";
    close $fh;
    cfork_exit(0);
});
ok(defined $child && $child > 0, 'reporter child started');
cfork_nonblocking(0);
ok(cfork_wait(2), 'reap isolation test');
my $text = slurp($report);
like($text, qr/^child$/m, 'child knows it is a child');
like($text, qr/^nohas$/m, 'child has no children of its own');
like($text, qr/^pids:$/m, 'child pid list is empty');
unlike($text, qr/\b\Q$sib\E\b/, 'sibling pid was dropped');

# Every code reference runs in the child.
fresh(2);
cfork_nonblocking(1);
my $multi = "$dir/multi";
$pid = cfork(
    sub {
        open my $fh, '>', $multi or exit 98;
        print {$fh} "one\n";
        close $fh;
    },
    sub {
        open my $fh, '>>', $multi or exit 98;
        print {$fh} "two\n";
        close $fh;
        cfork_exit(0);
    },
);
ok(defined $pid && $pid > 0, 'multi-code cfork returns a pid');
cfork_nonblocking(0);
ok(cfork_wait(2), 'reap multi-code child');
is(slurp($multi), "one\ntwo\n", 'child runs every code reference');

# Timeout, then kill.
fresh(2);
cfork_nonblocking(1);
$pid = cfork(sub { cfork_sleep(3); cfork_exit(0); });
ok(defined $pid && $pid > 0, 'long child started');
cfork_nonblocking(0);
$t0 = time();
ok(!cfork_wait(0.4), 'wait timeout returns false');
$elapsed = time() - $t0;
cmp_ok($elapsed, '>=', 0.3, 'timeout waited');
cmp_ok($elapsed, '<', 1.5, 'timeout returned before the child finished');
is(cfork_has_children(), 1, 'child still alive after timeout');
cfork_kill_children('TERM');
ok(cfork_wait(2), 'TERM cleared the pool');
is(cfork_active_children(), 0, 'no children after kill');

# wait_pid waits for one pid and leaves its sibling tracked.
fresh(4);
cfork_nonblocking(1);
my $slow = cfork(sub { cfork_usleep(700000); cfork_exit(0); });
my $fast = cfork(sub { cfork_usleep(150000); cfork_exit(0); });
ok(defined $slow && $slow > 0 && defined $fast && $fast > 0, 'wait_pid children started');
cfork_nonblocking(0);
ok(cfork_wait_pid($fast), 'wait_pid returns when that pid exits');
is_deeply([sort { $a <=> $b } cfork_list_children()], [$slow], 'sibling still tracked');
ok(cfork_wait(2), 'reap wait_pid sibling');

fresh(2);
cfork_nonblocking(1);
$pid = cfork(sub { cfork_usleep(400000); cfork_exit(0); });
$t0 = time();
ok(cfork_wait_pid($pid), 'nonblocking wait_pid does not wait');
cmp_ok(time() - $t0, '<', 0.2, 'nonblocking wait_pid returned quickly');
is(cfork_active_children(), 1, 'child still active after nonblocking wait_pid');
cfork_nonblocking(0);
ok(cfork_wait(2), 'reap nonblocking wait_pid child');

# Sleep wrappers.
is(cfork_usleep('nope'), undef, 'usleep rejects text');
is(cfork_usleep(-5), undef, 'usleep rejects a negative');
is(cfork_usleep(), undef, 'usleep rejects an omitted argument');
is(cfork_sleep('x'), undef, 'sleep rejects text');
is(cfork_ssleep(''), undef, 'ssleep rejects an empty string');
is(cfork_usleep(0), 0, 'usleep of zero');
is(cfork_sleep(0), 0, 'sleep of zero');
is(cfork_ssleep(0), 0, 'ssleep of zero');

$t0 = time();
my $slept = cfork_usleep(100000);
my $wall = time() - $t0;
cmp_ok($slept, '>=', 100000, 'usleep returns microseconds slept');
cmp_ok($slept, '<', 1000000, 'usleep return is bounded');
cmp_ok($wall, '>=', 0.08, 'usleep wall clock');
cmp_ok($wall, '<', 1, 'usleep wall clock upper bound');

$t0 = time();
$slept = cfork_sleep(1);
$wall = time() - $t0;
is($slept, 1, 'sleep returns seconds slept');
cmp_ok($wall, '>=', 0.9, 'sleep wall clock');
cmp_ok($wall, '<', 2.5, 'sleep wall clock upper bound');

{
    no warnings qw(once redefine);
    local *CORE::GLOBAL::sleep = sub { die "sleep() called\n" };
    $t0 = time();
    my $selected = eval { cfork_ssleep(1) };
    my $error = $@;
    $wall = time() - $t0;
    is($error, '', 'ssleep does not call sleep()');
    is($selected, 1, 'ssleep returns the requested seconds');
    cmp_ok($wall, '>=', 0.9, 'ssleep wall clock');
    cmp_ok($wall, '<', 2.5, 'ssleep wall clock upper bound');
}

# A zero cap is stored and rejects forks. A later init allows them again.
fresh(2);
is(cfork_maxchildren(), 2, 'maxchildren reads the current cap');
is(cfork_maxchildren(0), 0, 'maxchildren accepts zero');
is(cfork(sub { cfork_exit(0) }), undef, 'cfork fails when the cap is zero');
my $err = cfork_errstr();
$err = '' unless defined $err;
like($err, qr/cfork_init/, 'errstr explains the failure');
ok(cfork_init(0), 'init stores a zero cap');
is(cfork(sub { cfork_exit(0) }), undef, 'cfork fails after cfork_init(0)');
ok(cfork_init(2), 'init restores a usable cap');
cfork_nonblocking(0);
$pid = cfork(sub { cfork_exit(0); });
ok(defined $pid && $pid > 0, 'cfork works after re-init');

SKIP: {
    skip 'set TEST_DAEMONIZE=1 to run daemonize checks', 1
        unless $ENV{TEST_DAEMONIZE};

    my $daemon = fork;
    die "fork: $!" unless defined $daemon;
    if ($daemon == 0) {
        cfork_daemonize(1);
        exit 0;
    }
    waitpid($daemon, 0);
    is($? >> 8, 4, 'daemonize caller exits 4');
}

alarm(0);
open my $warn_fh, '<', $warnfile or die "open $warnfile: $!";
my $warnings = do { local $/; <$warn_fh> };
close $warn_fh;
$warnings = '' unless defined $warnings;
is($warnings, '', 'no warnings from Proc::Fork::Control')
    or diag($warnings);

done_testing();
