#!/usr/bin/perl

use 5.032;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use OEIS;

my %exp = (
    A000045 => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377,
                610, 987, 1597, 2584, 4181, 6765, 10946, 17711, 28657,
                46368, 75025, 121393, 196418, 317811, 514229, 832040, 1346269,
                2178309, 3524578, 5702887, 9227465, 14930352, 24157817,
                39088169, 63245986, 102334155, 165580141, 267914296,
                433494437, 701408733, 1134903170, 1836311903, 2971215073,
                4807526976, 7778742049],
);

foreach my $sequence (sort keys %exp) {
    my $exp = $exp {$sequence};
    my @got = oeis ($sequence, scalar @$exp);
    is_deeply \@got, $exp, sprintf "First %d integers of sequence %s " .
                                   "(some calculated)" =>
                                    scalar @$exp, $sequence;
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
