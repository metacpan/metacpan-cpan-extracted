use strict;
use warnings;

use Test::More;

use RPi::Const qw(:int_edge);

is INT_EDGE_SETUP,   0, "INT_EDGE_SETUP ok";
is INT_EDGE_FALLING, 1, "INT_EDGE_FALLING ok";
is INT_EDGE_RISING,  2, "INT_EDGE_RISING ok";
is INT_EDGE_BOTH,    3, "INT_EDGE_BOTH ok";

done_testing();
