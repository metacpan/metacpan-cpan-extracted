use strict;
use warnings;

use Test::More;

use RPi::WiringPi;

if (! $ENV{RPI_OLED}){
    plan skip_all => "RPI_OLED environment variable not set\n";
}

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}


my $s = RPi::WiringPi->oled('128x64', 0x3C, 0);

ok 1;

done_testing();

