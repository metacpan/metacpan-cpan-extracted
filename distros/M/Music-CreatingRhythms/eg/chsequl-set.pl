#!/usr/bin/env perl
use strict;
use warnings;

# Generate Christoffel word sets.

use Data::Dumper::Compact qw(ddc);
use Music::CreatingRhythms ();

my $t = shift || 'u'; # type of word: u=upper, l=lower
my $p = shift || 2;   # numerator of slope
my $m = shift || 14;  # maximum denominator
my $n = shift || 16;  # number of terms to generate

my $mcr = Music::CreatingRhythms->new;

for my $q (1 .. $m) {
    my $sequence = $mcr->chsequl($t, $p, $q, $n);
    print ddc($sequence, {max_width=>128});
}
