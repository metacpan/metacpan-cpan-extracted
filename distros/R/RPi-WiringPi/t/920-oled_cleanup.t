use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status oled_available oled_unavailable);
use Test::More;
use RPi::Const;
use RPi::WiringPi;

if (! $ENV{RPI_OLED}){
    plan skip_all => "RPI_OLED environment variable not set\n";
}

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

is oled_available(), 0, "oled still unavailable for use";
is oled_available(1), 1, "oled now available";
is -e '/tmp/oled_unavailable.rpi-wiringpi', undef, "oled lock file removed ok";

done_testing();

