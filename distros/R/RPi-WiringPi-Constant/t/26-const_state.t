use strict;
use warnings;

use Test::More;

use RPi::WiringPi::Constant qw(:state);


is HIGH, 1, "HIGH ok";
is LOW, 0, "LOW ok";
is ON, 1, "OFF ok";
is OFF, 0, "ON ok";

done_testing();
