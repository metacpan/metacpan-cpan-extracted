use strict;
use warnings;

use Test::More;

use RPi::Const qw(:altmode);

# Values are deliberately non-sequential (wiringPi funcsel ordering).
is ALT0, 4, "ALT0 ok";
is ALT1, 5, "ALT1 ok";
is ALT2, 6, "ALT2 ok";
is ALT3, 7, "ALT3 ok";
is ALT4, 3, "ALT4 ok";
is ALT5, 2, "ALT5 ok";

done_testing();
