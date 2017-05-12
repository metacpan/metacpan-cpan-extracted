use strict;
use warnings;

use Test::More;

use RPi::WiringPi::Constant qw(:edge);


is EDGE_SETUP, 0, "EDGE_SETUP ok";
is EDGE_FALLING, 1, "EDGE_FALLING ok";
is EDGE_RISING, 2, "EDGE_RISING ok";
is EDGE_BOTH, 3, "EDGE_BOTH ok";

done_testing();
