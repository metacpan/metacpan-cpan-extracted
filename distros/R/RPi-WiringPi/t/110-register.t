use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use Test::More;

my $mod = 'RPi::WiringPi';

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

my $pi = $mod->new(fatal_exit => 0);

my $pin26 = $pi->pin(26);
my $pin12 = $pi->pin(12);
my $pin18 = $pi->pin(18);

my %pin_map = (
    26 => $pin26,
    12 => $pin12,
    18 => $pin18,
);

my $pins = $pi->registered_pins;

is @$pins, 3, "proper num of pins registered";

for (keys %pin_map){
    is $pin_map{$_}->num, $_, "\$pin$_ has proper num()";
}

$pi->cleanup;

is @{ $pi->registered_pins }, 0, "after cleanup, all pins unregistered";

check_pin_status();

done_testing();

