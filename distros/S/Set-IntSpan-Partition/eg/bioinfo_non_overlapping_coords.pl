#!perl

use strict;
use warnings;

use Set::IntSpan;
use Set::IntSpan::Partition qw(intspan_partition);

# bioinformatics problem: https://www.biostars.org/p/7825/
#
# How To Get Non-Overlapping Coordinates From A List That Contains
# Overlapping Coordinates?
#
# chr1    1       10
# chr1    15      20
# chr1    17      30
# chr1    18      19
#
# This maps to the intervals (1, 10), (15, 20), (17, 30) and (18, 19).
# What is the list of non-overlapping intervals?

my @spans = (
    Set::IntSpan->new('1-10'),
    Set::IntSpan->new('15-20'),
    Set::IntSpan->new('17-30'),
    Set::IntSpan->new('18-19'),
);

my @output = intspan_partition @spans;
my @sorted = sort { $a cmp $b } map "$_", @output;

print join ',', @sorted;
