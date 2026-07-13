use strict;
use warnings;

use Test::More;

use RPi::Const qw(:wiringpi);

is WIRINGPI_MIN_VERSION, '3.18', "WIRINGPI_MIN_VERSION ok";

done_testing();
