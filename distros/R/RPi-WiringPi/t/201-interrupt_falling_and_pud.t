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
    label => 't/201-interrupt_falling_and_pud.t',
    shared => 0,
    shm_key => 'rpit'
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # EDGE_FALLING

    $pin->set_interrupt(EDGE_FALLING, \&handler);

    $pin->pull(PUD_UP);

    # trigger the interrupt

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);

    $pi->wait_interrupts(500);
    is $interrupts, 1, "1st interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);

    $pi->wait_interrupts(500);
    is $interrupts, 2, "2nd interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);

    $pi->wait_interrupts(500);
    is $interrupts, 3, "3rd interrupt ok";

    $pin->pull(PUD_DOWN);
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
