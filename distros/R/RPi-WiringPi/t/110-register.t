use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

my $mod = 'RPi::WiringPi';

my $obj_count = rpi_legal_object_count(); # in use, existing objects
my $pin_count = rpi_legal_pin_count(); # in use, existing objects

rpi_running_test(__FILE__);

{
    # with registration

    my $pi = $mod->new(fatal_exit => 0, label => 't/110-register.t', shm_key => 'rpit');

    my $pin26 = $pi->pin(26, '26:t/110-register.t');
    my $pin12 = $pi->pin(12, '12:t/110-register.t');
    my $pin18 = $pi->pin(18, '18:t/110-register.t');

    my %pin_map = (
        26 => $pin26,
        12 => $pin12,
        18 => $pin18,
    );

    my $pins = $pi->registered_pins;

    is @$pins, 3, "proper num of pins registered";

    for (keys %pin_map) {
        is $pin_map{$_}->num, $_, "\$pin$_ has proper num()";
        is $pin_map{$_}->comment, "$_:t/110-register.t", "...and has proper comment";
    }

    $pi->cleanup;

    #is @{ $pi->registered_pins }, 0, "after cleanup, all pins unregistered";

    rpi_check_pin_status();
    #rpi_metadata_clean();
}

{ # no register object

    my $pi = $mod->new(
        rpi_register => 0,
        fatal_exit => 0,
        label => 't/110-register.t',
        shm_key => 'rpit',
    );

    my $pin26 = $pi->pin(26, '26:t/110-register.t');
    my $pin12 = $pi->pin(12, '12:t/110-register.t');
    my $pin18 = $pi->pin(18, '18:t/110-register.t');

    my $m = $pi->meta_fetch;

    is keys %{ $m->{objects} }, $obj_count, "with rpi_register unset, object count ok";
    is keys %{ $m->{pins} }, $pin_count, "with rpi_register unset, pin count ok";

    $pi->cleanup;
    rpi_check_pin_status();
}

{ # no register pin

    my $pi = $mod->new(
        rpi_register_pins => 0,
        fatal_exit => 0,
        label => 't/110-register.t',
        shm_key => 'rpit',
    );

    my $pin26 = $pi->pin(26, '26:t/110-register.t');
    my $pin12 = $pi->pin(12, '12:t/110-register.t');
    my $pin18 = $pi->pin(18, '18:t/110-register.t');

    my $m = $pi->meta_fetch;

    is keys %{ $m->{objects} }, $obj_count + 1, "with rpi_register_pin unset, object count +1 ok";
    is keys %{ $m->{pins} }, $pin_count, "with rpi_register_pin unset, pin count ok";

    $pi->cleanup;
    rpi_check_pin_status();
}

done_testing();

