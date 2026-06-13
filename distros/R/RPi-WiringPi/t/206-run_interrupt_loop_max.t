use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

# In-process interrupt callback counter (a file lexical, not an env var gate)

my $interrupts = 0;

sub handler {
    $interrupts++;
}

my $pi = $mod->new(
    label => 't/206-run_interrupt_loop_max.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # run_interrupt_loop($timeout, $max) accumulates wait_interrupts() counts
    # and stops once $max events are seen. Pre-fill a known burst so $max is
    # reachable; the alarm watchdog catches the hang if it never is.

    my $max = 3;

    $pin->set_interrupt(EDGE_RISING, \&handler);

    $pin->pull(PUD_DOWN);

    for (1 .. $max){
        $pin->pull(PUD_UP);
        select(undef, undef, undef, 0.02);
        $pin->pull(PUD_DOWN);
        select(undef, undef, undef, 0.02);
    }

    select(undef, undef, undef, 0.1);

    my $total;

    eval {
        local $SIG{ALRM} = sub { die "run_interrupt_loop() hung\n" };
        alarm 20;
        $total = $pi->run_interrupt_loop(200, $max);
        alarm 0;
    };
    alarm 0;

    ok ! $@, "run_interrupt_loop() terminated via \$max (no hang) ok" or diag $@;
    is $total, $max, "run_interrupt_loop(200, $max) returned $max ok";
    is $interrupts, $max, "callback fired $max times ok";

    # a single pre-filled edge with $max == 1 returns 1

    $pin->pull(PUD_UP);
    select(undef, undef, undef, 0.02);
    $pin->pull(PUD_DOWN);

    select(undef, undef, undef, 0.1);

    my $one;

    eval {
        local $SIG{ALRM} = sub { die "run_interrupt_loop() hung\n" };
        alarm 20;
        $one = $pi->run_interrupt_loop(100, 1);
        alarm 0;
    };
    alarm 0;

    ok ! $@, "run_interrupt_loop(100, 1) terminated (no hang) ok" or diag $@;
    is $one, 1, "run_interrupt_loop(100, 1) returned 1 ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
