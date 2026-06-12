use strict;
use warnings;

use Test::More;

use RPi::Const qw(:wpi_pin);

is WPI_PIN_BCM, 1, "WPI_PIN_BCM ok";
is WPI_PIN_WPI, 2, "WPI_PIN_WPI ok";

done_testing();
