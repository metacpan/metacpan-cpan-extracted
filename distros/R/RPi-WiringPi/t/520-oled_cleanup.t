use strict;
use warnings;

use lib 't/';

use RPiTest;
use Test::More;
use RPi::Const;
use RPi::WiringPi;

if (! $ENV{RPI_OLED}){
    plan skip_all => "RPI_OLED environment variable not set\n";
}

rpi_running_test(__FILE__);

is rpi_oled_available(), 0, "oled still unavailable for use";
is rpi_oled_available(1), 1, "oled now available";
is -e '/dev/shm/oled_unavailable.rpi-wiringpi', undef, "oled lock file removed ok";

done_testing();

