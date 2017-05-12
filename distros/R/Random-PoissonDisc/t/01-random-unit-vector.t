#!perl -w
use strict;
use Test::More;
use Random::PoissonDisc;

my $tests = 100;
my $dimensions = 10;

plan tests => $tests*$dimensions;

# Sample $tests vectors and check their length

for my $dim (1..$dimensions) {
    for (1..$tests) {
        my $v = Random::PoissonDisc::random_unit_vector($dim);
        my $n = Random::PoissonDisc::norm(@$v);
        
        cmp_ok abs($n-1), '<=', 0.0001, "Dimension $dim"
            or diag "Dimension $dim: Generated @$v with norm $n";
    };
};