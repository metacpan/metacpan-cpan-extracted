use strict;
use warnings;

use Test::More;

use RPi::WiringPi::Constant qw(:pull);


is PUD_OFF, 0, "PUD_OFF ok";
is PUD_DOWN, 1, "PUD_DOWN ok";
is PUD_UP, 2, "PUD_UP ok";

done_testing();
