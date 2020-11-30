use strict;
use warnings;

use Test::More;

use String::Binary::Interpolation;

is("ABC${b01000100}", "ABCD", "can interpolate a byte");

done_testing();
