#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $v = [2, 3, 4];
my $r = $m->mul_vec_rows($v);

ok(ref($r) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($r->get(0, 0), 2, 'first row, first col (1*2)');
is($r->get(0, 2), 12, 'first row, last col (3*4)');
is($r->get(1, 1), 15, 'second row, middle col (5*3)');
