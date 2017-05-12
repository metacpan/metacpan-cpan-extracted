#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

use POSIX qw(pause :signal_h :sys_wait_h);
use_ok('Proc::Terminator');

# Try with a single PID first, right?

my @SIG_ORDER = (
    SIGINT,
    SIGQUIT,
    SIGKILL
);

my $MAX_WAIT = 5;
my $GRACE_PERIOD = 1;
my $CHILD_DEAD = 0;
my $PID;

$SIG{CHLD} = sub {
    waitpid($PID, WNOHANG);
    diag sprintf(
        "REAP %d. WIFSIGNALED: %d WTERMSIG: %d",
        $PID, WIFSIGNALED($?), WTERMSIG($?));
    $CHILD_DEAD = 1;
};

sub _forkproc {
    local $SIG{INT} = 'IGNORE';
    local $SIG{QUIT} = 'IGNORE';
    $PID = fork();
    die "Couldn't fork" unless $PID >= 0;
    diag "SPAWN $PID" if $PID;
    
    if ($PID==0) {
        
        alarm(7);
        while (1) {
            POSIX::pause();
            warn("Interrupted..");
        }
        die("We shouldn't get here!");
    }
}

my $ret;

my ($BEGIN_TIME,$DURATION);
$BEGIN_TIME = time();

_forkproc();
$ret = proc_terminate($PID, max_wait => $MAX_WAIT, grace_period => $GRACE_PERIOD);
$DURATION = time() - $BEGIN_TIME;

ok($DURATION > 1, "We slept a bit waiting");
ok($DURATION < 3, "We didn't sleep too much");
ok($ret, "Killed successfuly");

$BEGIN_TIME = time();
_forkproc();
$ret = proc_terminate($PID, max_wait => 5, siglist => [SIGINT], grace_period => 0.5);
$DURATION = time() - $BEGIN_TIME;

ok($DURATION < 1.5, "Waited less than 1.5 secs");
ok(!$ret, "Couldn't kill with ignored signal");

$BEGIN_TIME = time();
$ret = proc_terminate($PID, max_wait => 0.1, siglist => [SIGTERM]);
$DURATION = time() - $BEGIN_TIME;
ok($DURATION < 1, "Slept less than a second");
ok($ret, "Killed ok with SIGTERM");

done_testing();
