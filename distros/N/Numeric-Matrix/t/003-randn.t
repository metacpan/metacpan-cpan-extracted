#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::randn(3, 4);
ok(ref($m) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($m->rows, 3, 'rows');
is($m->cols, 4, 'cols');
# randn should have non-zero values (very unlikely all zeros)
ok($m->sum != 0 || $m->norm > 0, 'non-trivial values');
