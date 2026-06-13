use strict;
use warnings;

use lib 't/';

use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;
use Time::HiRes qw(usleep);
use WiringPi::API qw(read_pin write_pin);

# $pi->worker() is a thin proxy onto WiringPi::API::worker(): it forks a child
# that runs arbitrary Perl, tracks the returned handle on the object, and reaps
# it in cleanup(). Every block above the final one touches no hardware and runs
# off-Pi; the RPI_BOARD-gated block at the end drives a real pin through a worker.

my $mod = 'RPi::WiringPi';

# ---------------------------------------------------------------------------
# Off-Pi: validation, handle, lifecycle and cleanup reaping. NO_BOARD keeps
# new() from touching GPIO, and rpi_register*=>0 keeps it out of the shared
# meta store so the block is self-contained and side-effect-free.
# ---------------------------------------------------------------------------

{
    local $ENV{NO_BOARD} = 1;

    my $pi = $mod->new(
        label             => 't/213-worker.t',
        shm_key           => 'rpit',
        rpi_register      => 0,
        rpi_register_pins => 0,
    );

    # Argument validation is owned by WiringPi::API; the proxy must let those
    # croaks propagate unchanged rather than duplicating the checks.

    eval { $pi->worker() };
    like($@, qr/CODE reference/, 'worker() with no body croaks');

    eval { $pi->worker("notcode") };
    like($@, qr/CODE reference/, 'worker() with a non-CODE body croaks');

    eval { $pi->worker(sub { 1 }, "notahash") };
    like($@, qr/hash reference/, 'worker() with non-HASH opts croaks');

    eval { $pi->worker(sub { 1 }, { interval => "soon" }) };
    like($@, qr/interval/, 'worker() with non-numeric interval croaks');

    eval { $pi->worker(sub { 1 }, { mechanism => 'bogus' }) };
    like($@, qr/'fork' or 'thread'/, 'worker() with unknown mechanism croaks');

    # Construction + lifecycle: the proxy returns the low-level handle class.

    {
        my $w = $pi->worker(sub { usleep 20_000 });
        isa_ok($w, 'WiringPi::API::Worker', 'handle');
        ok($w->pid > 0,  'pid() is a real pid');
        ok($w->running,  'running() true while alive');

        ok($w->stop,     'stop() returns true');
        ok($w->stop,     'stop() is idempotent');
        ok(! $w->running, 'running() false after stop');
    }

    # {results=>1}: the child writes each defined return value to the channel;
    # the parent drains a few, then proves stop() is idempotent on the handle.

    {
        my $i = 0;
        my $w = $pi->worker(
            sub { my $n = $i++; usleep 5_000; return $n; },
            { results => 1 },
        );

        isa_ok($w->fh, 'GLOB', 'results fh()');

        my @got;
        for (1 .. 50) {
            last if @got >= 3;
            my $v = $w->read;
            if (defined $v) {
                push @got, $v;
                next;
            }
            usleep 5_000;
        }

        ok(@got >= 3, 'results channel streamed several values') or diag "got: @got";
        is_deeply([@got[0 .. 2]], [0, 1, 2], 'streamed values arrive in order');

        ok($w->stop, 'stop() returns true');
        ok($w->stop, 'stop() is idempotent on a channelled worker');
        ok(! $w->running, 'running() false after stop');
    }

    # cleanup() reaps a tracked worker the user never stopped: after cleanup the
    # handle is no longer running and leaves no zombie behind.

    {
        my $w   = $pi->worker(sub { usleep 50_000 });
        my $pid = $w->pid;
        ok($w->running, 'tracked worker running before cleanup');

        $pi->cleanup;

        ok(! $w->running, 'cleanup() stopped the tracked worker');
        is(waitpid($pid, 1), -1, 'cleanup-stopped worker left no zombie');  # WNOHANG
    }
}

# ---------------------------------------------------------------------------
# Real hardware (opt-in via RPI_BOARD). The OO object does GPIO setup once; the
# forked worker inherits the mapped GPIO and drives BCM18, which the parent
# (sharing the hardware) reads back. cleanup() then stops the worker as part of
# normal object teardown. Driving an unwired output pin is electrically safe.
# ---------------------------------------------------------------------------

SKIP: {
    skip "set RPI_BOARD=1 (and wire nothing to BCM18) to run the GPIO worker tests", 6
        unless $ENV{RPI_BOARD};

    my $pi = $mod->new(label => 't/213-worker.t', shm_key => 'rpit');

    my $pin = $pi->pin(18);     # GPIO (BCM) scheme by default
    $pin->mode(OUTPUT);         # inherited by the forked worker

    my $w = $pi->worker(
        sub { write_pin(18, 1); usleep 20_000; write_pin(18, 0); usleep 20_000 },
    );

    isa_ok($w, 'WiringPi::API::Worker', 'GPIO worker handle');

    my %seen;
    for (1 .. 400) {
        $seen{ read_pin(18) } = 1;
        last if $seen{0} && $seen{1};
        usleep 5_000;
    }

    ok($seen{1}, 'worker drove the pin HIGH (parent saw it)');
    ok($seen{0}, 'worker drove the pin LOW (parent saw it)');

    my $pid = $w->pid;

    # cleanup() restores the pin and stops the tracked worker in one teardown.
    $pi->cleanup;

    ok(! $w->running, 'cleanup() stopped the GPIO worker');
    is(waitpid($pid, 1), -1, 'cleanup-stopped GPIO worker left no zombie');  # WNOHANG
    is(WiringPi::API::get_alt(18), 0, 'cleanup() restored BCM18 to its INPUT default');
}

done_testing();
