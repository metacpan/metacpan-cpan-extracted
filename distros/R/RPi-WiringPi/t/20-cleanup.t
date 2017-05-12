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

my $pi = $mod->new;

{# register, unregister

    my $pin1 = $pi->pin(1);
    my $pin2 = $pi->pin(2);
    my $pin3 = $pi->pin(3);

    my @pins = $pi->registered_pins;

    my $c = 1;
    for ($pin1, $pin2, $pin3){
        isa_ok $_, 'RPi::WiringPi::Pin';
        is $_->num, $c, "pin $c has correct num";
        $c++;
    }

    $pi->unregister_pin($pin3);
    is $pi->registered_pins, '1,2', "unregistered pin ok";

    $pi->register_pin($pin3);
    is $pi->registered_pins, '1,2,3', "registered pin ok";
 
    $pi->cleanup;

    is $pi->registered_pins, undef, "cleanup() ok";
}

done_testing();
