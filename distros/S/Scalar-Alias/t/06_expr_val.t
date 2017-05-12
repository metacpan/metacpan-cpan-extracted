#!perl -w

use strict;
use Test::More tests => 2;

use Scalar::Alias;

my $x = 10;
is scalar(my alias $y = $x), 10;

is scalar(my alias $z = 20), 20;
