use warnings;
use strict;

# V16 leak/behaviour harness for the OO $pi->worker(). Drives every worker()
# lifecycle path the t/213-worker.t suite touches, on a loop, so a leaked pipe
# fd, an unreaped child, or a leaked SV shows up in valgrind's summary (and a
# zombie shows up in waitpid). This is the OO sibling of WiringPi::API's
# testing/valgrind_worker.pl (Phase 1 / V8).
#
# Hardware: requires a Pi (the RPi::WiringPi object does setup_gpio + real
# pins). Drives BCM 23/24/25 as OUTPUTs - pins the test platform leaves unwired
# (see t/README), so this is electrically and functionally safe to run.
#
# {mechanism=>'thread'} is intentionally NOT exercised: it needs a threaded
# Perl ('use threads'), and the dist's Perl is built without ithreads. The fork
# path below is the default and the one the dist must keep leak-clean.

use RPi::WiringPi;
use RPi::Const qw(:all);
use WiringPi::API qw(read_pin write_pin);
use Time::HiRes qw(usleep);

my $iters = $ENV{ITERS} || 10;     # lower under valgrind (every fork is traced)
my @pins  = (23, 24, 25);

# NOTE: on a Pi 5 / RP1, cleanup() may print "pinModeAlt: invalid mode 31" when
# restoring pins whose default funcsel is "null" (31) - a wiringPi limitation in
# the library's pin restore, unrelated to worker(). Harmless here.

our @KEEP;          # handles deliberately left for the exit reaper
our $FORGOTTEN_PI;  # held until global destruction so exit does the reaping

my $pi = RPi::WiringPi->new(label => 'valgrind_worker.pl', shm_key => 'rpit');

for my $pin (@pins) {
    my $p = $pi->pin($pin);
    $p->mode(OUTPUT);
    write_pin($pin, 0);
}

exercise_distinct_pin_workers();
exercise_interval_worker();
exercise_once_worker();
exercise_shared_sampler();
exercise_stop_and_reap();
exercise_cleanup_driven_stop();

write_pin($_, 0) for @pins;

# Normal teardown of the driving object: stops any workers still tracked on it
# and restores the pins. Done BEFORE forgotten-stop so that scenario's handles
# are reaped only at process exit, not by this cleanup.
$pi->cleanup;

# Last: leave workers running with no stop() and no cleanup() so the process
# exit reaper (WiringPi::API's END block, plus the object's DESTROY->cleanup) is
# the only thing that can clean them up.
exercise_forgotten_stop();

print "valgrind_worker.pl: all OO worker scenarios exercised ($iters iters each)\n";

# cleanup-driven stop: spawn workers via $pi->worker and never stop them by
# hand; $pi->cleanup() must stop every tracked handle and leave no zombie. This
# is the OO-specific reaping path (Core::cleanup) that DESTROY also routes
# through. A fresh object keeps it isolated from the long-lived $pi above.
sub exercise_cleanup_driven_stop {
    for (1 .. $iters) {
        my $c = RPi::WiringPi->new(
            label             => 'valgrind_worker.pl cleanup',
            shm_key           => 'rpit',
            rpi_register      => 0,
            rpi_register_pins => 0,
        );

        my @w = map { $c->worker(sub { usleep 20_000 }) } 1 .. 3;
        usleep 10_000;

        $c->cleanup;

        for my $w (@w) {
            die "cleanup-stop: worker still running"   if $w->running;
            die "cleanup-stop: zombie left for pid " . $w->pid
                if waitpid($w->pid, 1) != -1;          # WNOHANG
        }
    }
}

# Distinct-pin workers: three children each owning their own pin, running
# concurrently with the parent. stop() each, then prove no zombie remains.
sub exercise_distinct_pin_workers {
    for (1 .. $iters) {
        my @w;
        for my $pin (@pins) {
            push @w, $pi->worker(sub {
                write_pin($pin, 1); usleep 5_000;
                write_pin($pin, 0); usleep 5_000;
            });
        }

        usleep 40_000;
        $_->stop for @w;

        for my $w (@w) {
            die "distinct-pin: zombie left for pid " . $w->pid
                if waitpid($w->pid, 1) != -1;          # WNOHANG
        }
    }
}

# Forgotten stop: spawn workers and never stop them, keeping the handles alive
# so the process-exit reaper cleans them up (WiringPi::API's END block, and the
# object's DESTROY->cleanup). Runs last; valgrind + a manual `ps` confirm no
# leak/zombie.
sub exercise_forgotten_stop {
    $FORGOTTEN_PI = RPi::WiringPi->new(
        label             => 'valgrind_worker.pl forgotten',
        shm_key           => 'rpit',
        rpi_register      => 0,
        rpi_register_pins => 0,
    );

    for (1 .. 3) {
        push @KEEP, $FORGOTTEN_PI->worker(sub { usleep 20_000 });
    }

    print "forgotten-stop: spawned " . scalar(@KEEP)
        . " workers; exit must reap pids " . join(", ", map { $_->pid } @KEEP) . "\n";
}

# {interval => $secs}: the helper paces the loop and the body carries no sleep.
# Drain the results channel and require that pacing produced bounded passes.
sub exercise_interval_worker {
    for (1 .. $iters) {
        my $i = 0;
        my $w = $pi->worker(sub { return $i++; }, { interval => 0.01, results => 1 });

        usleep 100_000;
        $w->stop;

        my $n = 0;
        $n++ while defined $w->read;
        die "interval: no passes streamed" if $n < 1;
    }
}

# {once => 1}: body runs exactly once, the child exits on its own, running()
# goes false, and the single value arrives on the results channel.
sub exercise_once_worker {
    for (1 .. $iters) {
        my $w = $pi->worker(sub { return 42; }, { once => 1, results => 1 });

        for (1 .. 200) {
            last if ! $w->running;
            usleep 2_000;
        }
        die "once: child still running" if $w->running;

        my $got = $w->read;
        die "once: no value produced" if ! defined $got || $got != 42;

        $w->stop;       # Idempotent on an already-exited child
    }
}

# {shared => 1}: a sampler reads a pin the parent drives and publishes the
# latest level; the parent reads it back through value(). Exercises the lossy
# channel.
sub exercise_shared_sampler {
    for (1 .. $iters) {
        write_pin(23, 1);
        my $s = $pi->worker(sub { return read_pin(23); }, { shared => 1, interval => 0.01 });

        my $v;
        for (1 .. 100) {
            usleep 5_000;
            $v = $s->value;
            last if defined $v && $v == 1;
        }
        die "shared: sampler never saw HIGH" if ! defined $v || $v != 1;

        $s->stop;
    }
}

# Lifecycle: running() true while alive, stop() reaps with no zombie, stop() is
# idempotent and running() false afterwards.
sub exercise_stop_and_reap {
    for (1 .. $iters) {
        my $w   = $pi->worker(sub { usleep 10_000 });
        my $pid = $w->pid;

        die "stop/reap: not running after spawn" if ! $w->running;

        $w->stop;
        die "stop/reap: still running after stop" if $w->running;
        die "stop/reap: zombie left for pid $pid" if waitpid($pid, 1) != -1;

        $w->stop;       # Idempotent
    }
}
