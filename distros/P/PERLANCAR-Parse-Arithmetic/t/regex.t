#!perl

use 5.010001;
use strict;
use warnings;

use PERLANCAR::Parse::Arithmetic qw(parse_arithmetic);
use Test::More 0.98;

is(parse_arithmetic('1 + 2*3'), 7);
is(parse_arithmetic('(1 + 2) * 3'), 9);
is(parse_arithmetic('2**3**2'), 512);

DONE_TESTING:
done_testing;
