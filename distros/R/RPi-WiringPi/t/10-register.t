use strict;
use warnings;

use Data::Dumper;
use RPi::WiringPi;
use Test::More;

my $mod = 'RPi::WiringPi';

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

my $pi = $mod->new(fatal_exit => 0);

{# register, unregister

    my $pin1 = $pi->pin(1);
    my $pin2 = $pi->pin(2);
    my $pin3 = $pi->pin(3);

    my %pin_map = (
        1 => $pin1,
        2 => $pin2,
        3 => $pin3,
    );

    my $pins = $pi->registered_pins;
    is ((split /,/, $pins), 3, "proper num of pins registered");

    for (keys %pin_map){
        is $pin_map{$_}->num, $_, "\$pin$_ has proper num()";
    }
}

$pi->cleanup;

is $pi->registered_pins, undef, "after cleanup, all pins unregistered";

done_testing();

