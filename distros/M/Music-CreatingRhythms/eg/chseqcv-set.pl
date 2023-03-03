#!/usr/bin/env perl
use strict;
use warnings;

# Generate Christoffel word sequences of convergent series.

use Music::CreatingRhythms ();

my $t = shift || 'u'; # type of word: u=upper, l=lower

my $mcr = Music::CreatingRhythms->new;

for my $i (2, 3, 5, 17) {
    print "$i:\n";
    for my $j (1 .. 3) {
        my $terms = $mcr->cfsqrt($i, $j);
        print "Ts: ", join(', ', @$terms), "\n";
        my $convergent = $mcr->cfcv(@$terms);
        print "\tCv: ", join(', ', @$convergent), "\n";
        my $sequence = $mcr->chsequl($t, $convergent->[0], $convergent->[1]);
        print "\t\tCh: ", join(' ', @$sequence), "\n";
    }
    print '-' x 50, "\n";
}
