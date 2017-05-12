#!perl -w

use strict;
use Test::More tests => 2;

use Scalar::Alias;

my $x = 10;
ok scalar(my alias($y) = $x);

is_deeply [my alias($a, $b) = (20, 30)], [20, 30];
