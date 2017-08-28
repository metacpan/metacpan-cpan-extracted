#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


#
# Copyright (C) 2016 J. Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended;
use Range::Merge::Boilerplate 'script';

use Range::Merge qw(merge);

use Perl6::Slurp;

MAIN: {
    my @lines;
    @lines = slurp '<t/data/level3-ranges-from-routeviews.txt';
    my (@indata) = map { chomp; s/^([^-]+)-/$1\t/ ; [ split /\t/ ] } @lines;

    # pretty_diag(\@indata);

    my $result = merge(\@indata);

    is(scalar(@$result), 331215, 'Merge returns the right number of ranges');

    my (@sorted) = sort { $a->[0] < $b->[0] } @$result;
    is(@sorted, @$result);

    done_testing;
}

sub pretty_diag($ranges) {
    diag "Values:";
    diag join "\n", map  { "  [" . join(",", $_->@*) . "]" } $ranges->@*;
}

1;
