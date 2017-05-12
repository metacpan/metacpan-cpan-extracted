use strict;
use warnings;

use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);
use Test::More;

my $mod = 'RPi::WiringPi';

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

my $pi = $mod->new(fatal_exit => 0);
my $pin = $pi->pin(5);
$pin->mode(OUTPUT);
is $pi->registered_pins, '5', "pin registered ok";

eval { die "intentional die()"; };

is $pin->mode, 0, "pin reset to INPUT after die()";

done_testing();
