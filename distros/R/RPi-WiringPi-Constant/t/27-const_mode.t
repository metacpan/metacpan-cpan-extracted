use strict;
use warnings;

use Test::More;
use RPi::WiringPi::Constant qw(:mode);

is RPI_MODE_WPI,        0, "WPI == 0";
is RPI_MODE_GPIO,       1, "GPIO == 1";
is RPI_MODE_GPIO_SYS,   2, "GPIO_SYS == 2";
is RPI_MODE_PHYS,       3, "PHYS == 3";
is RPI_MODE_UNINIT,    -1, "UNINIT == -1";

done_testing();
