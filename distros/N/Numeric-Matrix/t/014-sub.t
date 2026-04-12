#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([10, 20, 30, 40], 2, 2);
my $b = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
my $c = $a->sub($b);

ok(ref($c) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($c->get(0, 0), 9, 'sub [0,0]');
is($c->get(1, 1), 36, 'sub [1,1]');
