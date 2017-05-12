use strict;
use warnings;

use Test::More;
use RPi::WiringPi::Constant qw(:all);

# pinmode

is INPUT, 0, "INPUT const ok";
is OUTPUT, 1, "OUTPUT const ok";
is PWM_OUT, 2, "PWM_OUT const ok";
is GPIO_CLOCK, 3, "GPIO_CLOCK const ok";
is SOFT_PWM_OUTPUT, 4, "SOFT_PWM_OUTPUT ok";
is SOFT_TONE_OUTPUT, 5, "SOFT_TONE_OUTPUT ok";
is PWM_TONE_OUTPUT, 6, "PWM_TONE_OUTPUT ok";

# pull

is PUD_OFF, 0, "PUD_OFF ok";
is PUD_DOWN, 1, "PUD_DOWN ok";
is PUD_UP, 2, "PUD_UP ok";

# state

is HIGH, 1, "HIGH ok";
is LOW, 0, "LOW ok";
is ON, 1, "OFF ok";
is OFF, 0, "ON ok";

# mode

is RPI_MODE_WPI,        0, "WPI == 0";
is RPI_MODE_GPIO,       1, "GPIO == 1";
is RPI_MODE_GPIO_SYS,   2, "GPIO_SYS == 2";
is RPI_MODE_PHYS,       3, "PHYS == 3";
is RPI_MODE_UNINIT,    -1, "UNINIT == -1";

# edge

is EDGE_SETUP, 0, "EDGE_SETUP ok";
is EDGE_FALLING, 1, "EDGE_FALLING ok";
is EDGE_RISING, 2, "EDGE_RISING ok";
is EDGE_BOTH, 3, "EDGE_BOTH ok";

done_testing();
