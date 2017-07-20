use strict;
use warnings;

use Test::More;
use RPi::Const qw(:pwm_mode);

# pwm_mode

is PWM_MODE_MS, 0, "PWM_MODE_MS ok";
is PWM_MODE_BAL, 1, "PWM_MODE_BAL ok";

done_testing();
