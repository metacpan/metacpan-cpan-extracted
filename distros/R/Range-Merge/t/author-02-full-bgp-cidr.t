#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


#
# Copyright (C) 2016 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended;
use Range::Merge::Boilerplate 'script';

use Range::Merge qw(merge_ipv4);

use Perl6::Slurp;

MAIN: {
    my @lines;
    @lines = slurp '<t/data/level3-full-from-routeviews.txt';
    my (@indata) = map { chomp; [ split /\t/ ] } @lines;

    # pretty_diag(\@indata);

    my $result = merge_ipv4(\@indata);

    is(scalar(@$result), 461222, 'Merge returns the right number of CIDRs');

    done_testing;
}

sub pretty_diag($ranges) {
    diag "Values:";
    diag join "\n", map  { "  [" . join(",", $_->@*) . "]" } $ranges->@*;
}

1;
