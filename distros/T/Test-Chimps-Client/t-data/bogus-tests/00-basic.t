#!perl -T

use Test::More tests => 3;

is(1, 1);

ok(1+1 == 2);

isnt(2+2, 5);
