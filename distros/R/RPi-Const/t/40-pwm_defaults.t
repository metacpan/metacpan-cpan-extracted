use strict;
use warnings;

use Test::More;
use RPi::Const qw(:pwm_defaults);

# pwm_defaults

is PWM_DEFAULT_MODE, 1, "PWM default mode ok";
is PWM_DEFAULT_CLOCK, 32, "PWM default clock ok";
is PWM_DEFAULT_RANGE, 1023, "PWM default range ok";

done_testing();
