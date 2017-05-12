#!/usr/bin/perl

use strict;
use warnings;

use String::LCSS_XS qw(lcss_all);

my ($s,$t) = @ARGV;
if (!defined $s || !defined $t) {
    print "Usage: $0 string1 string2\n";
    exit 1;
}

print "The longest common substrings of:\n\n\t$s\n\nand\n\n\t$t\n\nare:\n\n";
my @results = lcss_all ( $s, $t );
for my $result (@results) {
    print "\t$result->[0] ($result->[1],$result->[2])\n";
}
