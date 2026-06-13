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
    label => 't/205-stop_interrupts.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # arm, fire one edge and confirm it dispatches

    $pin->set_interrupt(EDGE_RISING, \&handler);

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    select(undef, undef, undef, 0.1);

    $pi->dispatch_interrupts();

    is $interrupts, 1, "edge dispatched while armed ok";

    # stop_interrupts tears the subsystem down: the self-pipe is gone and the
    # ISR is stopped, so further edges must not dispatch.

    $pi->stop_interrupts();

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    select(undef, undef, undef, 0.1);

    is $pi->wait_interrupts(200), 0,
        "wait_interrupts() returns 0 after stop_interrupts ok";
    is $interrupts, 1, "count frozen after stop_interrupts ok";

    # re-arming resumes dispatch from a fresh pipe

    $pin->set_interrupt(EDGE_RISING, \&handler);

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    select(undef, undef, undef, 0.1);

    $pi->dispatch_interrupts();

    is $interrupts, 2, "re-arming resumes dispatch ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
