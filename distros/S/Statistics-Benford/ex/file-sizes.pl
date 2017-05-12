#!/usr/bin/env perl
use strict;
use warnings;

use File::Next;
use List::Util qw(sum);
use Statistics::Benford;

my $files = File::Next::files({ error_handler => sub {}, }, @ARGV);
my $stats = Statistics::Benford->new;
my %freq;

while (defined (my $file = $files->())) {
    my $size = -s $file or next;
    my ($digit) = substr $size, 0, 1;
    $freq{$digit}++;
}

my %dist = $stats->dist;
my $sum = sum values %freq;

print "d expected found\n";

for my $digit (sort keys %dist) {
    my $p = $freq{$digit} ? ($freq{$digit} / $sum) : 0;
    printf "%d     %.2f  %.2f\n", $digit, $dist{$digit}, $p;
}

print "\n";
printf "diff: %.2f\n", scalar $stats->diff(%freq);
printf "z:    %.2f\n", scalar $stats->z(%freq);
