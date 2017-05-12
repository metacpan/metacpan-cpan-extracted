#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

my $max = (~0 >> 1);
my $min = -$max - 1;

for my $n (5, 5, 10, 10, 20, 20) {
    my @data;
    for (0 .. $n) {
        my $d = int rand 300;
        if ($d < 100) {
            $d += $min;
        }
        elsif ($d < 200) {
            $d -= 150;
        }
        else {
            $d += ($max - 300);
        }
        push @data, $d;
    }

    my @bad = grep {$_ > $max or $_ < $min} @data;
    ok(!@bad, "data generation")
        or diag "bad data: @bad";

    my @sorted_data = sort { int($a) <=> int($b) } @data;

    for my $algorithm (qw(insertion shell heap merge)) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algorithm}_sort"} };
        is_deeply($sorter->(\@data),
                  \@sorted_data,
                  "sorting $n integers using $algorithm algorithm")
            or diag "data: @data\n";
    }
}

done_testing;
