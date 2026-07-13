use strict;
use warnings;

use Test::More;

use RPi::Const qw(:mcp23017_pins);

# Bank A pins 0-7
is A0,  0, "A0 ok";
is A1,  1, "A1 ok";
is A2,  2, "A2 ok";
is A3,  3, "A3 ok";
is A4,  4, "A4 ok";
is A5,  5, "A5 ok";
is A6,  6, "A6 ok";
is A7,  7, "A7 ok";

# Bank B pins 8-15
is B0,  8, "B0 ok";
is B1,  9, "B1 ok";
is B2, 10, "B2 ok";
is B3, 11, "B3 ok";
is B4, 12, "B4 ok";
is B5, 13, "B5 ok";
is B6, 14, "B6 ok";
is B7, 15, "B7 ok";

done_testing();
