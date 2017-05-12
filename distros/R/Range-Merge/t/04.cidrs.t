#!/usr/bin/perl

#
# Copyright (C) 2016 Joel C. Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended;
use Range::Merge::Boilerplate 'script';

# Using data from: http://www.plover.com/~mjd/misc/merge-networks/
# See also Perl Monks: http://www.perlmonks.org/?node_id=118346
# 
# nm3b.out was changed by removing the last line - 255.255.255.255/32, 
# which was clearly covered by the second to last line - 255.255.255.254/32

use Range::Merge qw(merge_ipv4);

use Perl6::Slurp;

MAIN: {
    foreach my $base ( qw(1 2 3 3a 3b 4 4a 5 6 7a 7b 8) ) {
        run_test("nm$base");
    }

    done_testing;
}

sub run_test($filebase) {
    my @lines;
    @lines = slurp "<t/data/$filebase.in";
    my (@indata) = map { chomp; [ $_ ] } @lines;

    # pretty_diag(\@indata);

    my $result = merge_ipv4(\@indata);
    
    @lines = slurp "<t/data/$filebase.out";
    my (@expected) = map { chomp; [ $_ ] } @lines;

    is($result, \@expected, "$filebase data is as expected");
}

sub pretty_diag($ranges) {
    diag "Values:";
    diag join "\n", map  { "  [" . join(",", $_->@*) . "]" } $ranges->@*;
}

1;


