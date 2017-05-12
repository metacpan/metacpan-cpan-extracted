#!/usr/bin/perl -I../lib

use Test::Assert ':all';

use Test::More import => ['!fail'];
use Test::Differences;

my @a = (1,2,3,4,5);
my @b = (1,2,2,4,5);

sub test_differences {
    assert_test { eq_or_diff( \@a, \@b, 'testing eq_or_diff' ) };
}

test_differences;
