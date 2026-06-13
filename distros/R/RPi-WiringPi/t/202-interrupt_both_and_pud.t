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
    label => 't/202-interrupt_both_and_pud.t',
    shared => 0,
    shm_key => 'rpit'
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # EDGE_BOTH
    
    $pin->pull(PUD_DOWN);

    $pin->set_interrupt(EDGE_BOTH, \&handler);

    # trigger the interrupt

    select(undef, undef, undef, 0.02);
    $pin->pull(PUD_UP);
    select(undef, undef, undef, 0.02);
    $pin->pull(PUD_DOWN);
    select(undef, undef, undef, 0.02);

    $pi->wait_interrupts(500);
    is $interrupts, 2, "both interrupt up/down == 2 ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    select(undef, undef, undef, 0.02);
    $pin->pull(PUD_DOWN);
    select(undef, undef, undef, 0.02);

    $pi->wait_interrupts(500);
    is $interrupts, 4, "both interrupt up/down x2 == 4 ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    select(undef, undef, undef, 0.02);
    $pin->pull(PUD_DOWN);
    select(undef, undef, undef, 0.02);

    $pi->wait_interrupts(500);
    is $interrupts, 6, "both interrupt up/down x3 == 6 ok";

}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
