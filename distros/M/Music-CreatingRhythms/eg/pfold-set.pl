#!/usr/bin/env perl
use strict;
use warnings;

# Generate pfold binary sequences.

use Data::Dumper::Compact qw(ddc);
use Music::CreatingRhythms ();

my $n = shift || 16;  # number of terms
my $m = shift || 16;  # maximum iteration
my $f = shift || 4;   # folding function number 0 to (2^m)-1

die "Invalid folding function: $f\n"
    if $f > (2 ** $m) - 1;

my $mcr = Music::CreatingRhythms->new;

for my $i (0 .. $m - 1) {
    my $sequence = $mcr->pfold($n, $f, $i);
    print ddc($sequence, {max_width=>128});
}
