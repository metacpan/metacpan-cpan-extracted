#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::zeros(3, 4);
my @shape = $m->shape;
is(scalar(@shape), 2, 'shape returns 2 values');
is($shape[0], 3, 'rows in shape');
is($shape[1], 4, 'cols in shape');
