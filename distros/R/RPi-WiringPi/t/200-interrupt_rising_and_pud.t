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
    label => 't/200-interrupt_rising_and_pud.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # EDGE_RISING

    $pin->set_interrupt(EDGE_RISING, \&handler);

    $pin->pull(PUD_DOWN);

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    $pi->wait_interrupts(500);
    is $interrupts, 1, "1st interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    $pi->wait_interrupts(500);
    is $interrupts, 2, "2nd interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    $pi->wait_interrupts(500);
    is $interrupts, 3, "3rd interrupt ok";

}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
