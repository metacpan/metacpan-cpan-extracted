#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::ones(2, 3);
ok(ref($m) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($m->sum, 6, 'sum of ones(2,3)');
is($m->get(1, 2), 1, 'element value');
