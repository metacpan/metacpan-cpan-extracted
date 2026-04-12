#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $r = $m->row(1);

is(ref($r), 'ARRAY', 'row returns arrayref');
is(scalar(@$r), 3, 'correct length');
is_deeply($r, [4, 5, 6], 'correct values');

# out of bounds
eval { $m->row(5) };
like($@, qr/out of bounds/, 'out of bounds error');
