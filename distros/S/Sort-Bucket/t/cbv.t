# Testing src/calculate-bucket-values.c

use strict;
use warnings;

use Test::More tests => 2;
use Test::Group;
use Test::Group::Foreach;
use Sort::Bucket;

{
    next_test_foreach my $bits, 'b', 1 .. 31;
    next_test_foreach my $len, 'len', 0 .. 10;
    test all_zeros => sub {
        my ($maj, $min) = cbv("\0" x $len, $bits);
        is $maj, 0, "major 0";
        is $min, 0, "minor 0";
    };
}

{
    next_test_foreach my $bits, 'b', 1 .. 31;
    test all_ones => sub {
        my ($maj, $min) = cbv("\xFF" x 10, $bits);
        is $maj, 2**$bits-1, "major all 1s";
        is $min, 2**32-1,    "minor all 1s";
    };
}


sub cbv {
    my ($sv, $bits) = @_;

    my ($maj, $min);
    Sort::Bucket::_cbv_testharness($sv, $bits, $maj, $min);
    return ($maj, $min);
}

