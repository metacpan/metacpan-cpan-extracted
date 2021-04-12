#!/usr/bin/perl

use 5.032;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use OEIS;

use bigint;

my %exp = (
    A000045 => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377,
                610, 987, 1597, 2584, 4181, 6765, 10946, 17711, 28657,
                46368, 75025, 121393, 196418, 317811, 514229, 832040, 1346269,
                2178309, 3524578, 5702887, 9227465, 14930352, 24157817,
                39088169, 63245986, 102334155],
    A000110 => [1, 1, 2, 5, 15, 52, 203, 877, 4140, 21147, 115975, 678570,
                4213597, 27644437, 190899322, 1382958545, 10480142147,
                82864869804, 682076806159, 5832742205057, 51724158235372,
                474869816156751, 4506715738447323, 44152005855084346,
                445958869294805289, 4638590332229999353, 49631246523618756274],
);

foreach my $sequence (sort keys %exp) {
    my $exp = $exp {$sequence};
    my @got = oeis ($sequence);
    is_deeply \@got, $exp, sprintf "Listed integers of sequence %s" =>
                                    $sequence;
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
