use strict;
use warnings;

use lib 't/';

use POSIX ();
use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

my $pi = $mod->new(
    label => 't/207-stop_interrupt_loop.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # run_interrupt_loop() with no $max only stops when the callback calls
    # stop_interrupt_loop(). To prove the loop halts at the threshold rather
    # than draining the whole burst, a forked child paces more edges than the
    # threshold while the parent blocks in the loop.

    my $threshold = 3;
    my $burst     = 6;
    my $count     = 0;

    $pin->set_interrupt(EDGE_RISING, sub {
        $count++;
        $pi->stop_interrupt_loop if $count >= $threshold;
    });

    $pin->pull(PUD_DOWN);

    my $pid = fork;
    die "fork failed: $!\n" if ! defined $pid;

    if ($pid == 0){
        # child: generate a paced burst, well spaced so each edge lands in its
        # own loop iteration. _exit() so the shared $pi is not torn down here.
        select(undef, undef, undef, 0.3);

        for (1 .. $burst){
            $pin->pull(PUD_UP);
            select(undef, undef, undef, 0.05);
            $pin->pull(PUD_DOWN);
            select(undef, undef, undef, 0.15);
        }

        POSIX::_exit(0);
    }

    # parent: blocking loop with no $max - only the callback ends it

    my $total;

    eval {
        local $SIG{ALRM} = sub { die "run_interrupt_loop() hung\n" };
        alarm 20;
        $total = $pi->run_interrupt_loop(500);
        alarm 0;
    };
    alarm 0;
    my $err = $@;

    waitpid $pid, 0;

    ok ! $err,
        "run_interrupt_loop() ended via stop_interrupt_loop (no hang) ok"
        or diag $err;
    is $total, $threshold,
        "loop returned threshold ($threshold), not the full burst ($burst) ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
