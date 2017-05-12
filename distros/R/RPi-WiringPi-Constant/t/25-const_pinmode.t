use strict;
use warnings;

use Test::More;
use RPi::WiringPi::Constant qw(:pinmode);

is INPUT, 0, "INPUT const ok";
is OUTPUT, 1, "OUTPUT const ok";
is PWM_OUT, 2, "PWM_OUT const ok";
is GPIO_CLOCK, 3, "GPIO_CLOCK const ok";
is SOFT_PWM_OUTPUT, 4, "SOFT_PWM_OUTPUT ok";
is SOFT_TONE_OUTPUT, 5, "SOFT_TONE_OUTPUT ok";
is PWM_TONE_OUTPUT, 6, "PWM_TONE_OUTPUT ok";

done_testing();
