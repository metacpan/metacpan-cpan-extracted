#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, -2, 3, -4], 2, 2);
my $b = $a->abs;

ok(ref($b) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($b->get(0, 0), 1, 'abs(1)');
is($b->get(0, 1), 2, 'abs(-2)');
