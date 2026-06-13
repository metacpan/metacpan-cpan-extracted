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
    label => 't/204-last_interrupt.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # last_interrupt() publishes the most recently dispatched event as a
    # hashref. Arm RISING, fire one edge, drain, then inspect every field.

    $pin->set_interrupt(EDGE_RISING, \&handler);

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    select(undef, undef, undef, 0.1);

    $pi->dispatch_interrupts();

    my $rising = $pi->last_interrupt();

    is ref $rising, 'HASH', "last_interrupt() returns a hashref ok";

    for my $field (qw(pin pin_bcm edge status ts_us)){
        ok exists $rising->{$field}, "last_interrupt() has '$field' field ok";
    }

    is $rising->{pin_bcm}, 18, "last_interrupt() pin_bcm == 18 ok";
    is $rising->{edge}, EDGE_RISING, "last_interrupt() edge tracks armed RISING ok";
    cmp_ok $rising->{ts_us}, '>', 0, "last_interrupt() ts_us is positive ok";

    my $first_ts = $rising->{ts_us};

    # re-arm FALLING and confirm the edge field follows the newly armed type,
    # and that ts_us advances (monotonically increasing)

    $pin->set_interrupt(EDGE_FALLING, \&handler);

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    select(undef, undef, undef, 0.1);

    $pi->dispatch_interrupts();

    my $falling = $pi->last_interrupt();

    is $falling->{pin_bcm}, 18, "last_interrupt() pin_bcm still 18 ok";
    is $falling->{edge}, EDGE_FALLING,
        "last_interrupt() edge tracks armed FALLING ok";
    cmp_ok $falling->{ts_us}, '>', $first_ts,
        "last_interrupt() ts_us monotonically increasing ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
