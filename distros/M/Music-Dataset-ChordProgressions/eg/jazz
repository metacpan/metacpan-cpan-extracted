#!/usr/bin/env perl

# Return random jazz progressions

# Unfortunately, a couple chords have a "bV" note in the base, which is not handled by this code yet...

use strict;
use warnings;

use Music::Dataset::ChordProgressions qw(as_hash transpose);

my $n     = shift || 4;
my $note  = shift || 'C'; # Transpose chords from C to this
my $scale = shift || 'major'; # or minor

my %data = as_hash();

# List of jazz > scale > type chord progressions
my @pool = map { @{ $data{jazz}{$scale}{$_} } } keys %{ $data{jazz}{$scale} };

for my $i (1 .. $n) {
    my $progression = $pool[int rand @pool];
    my $named = transpose($note, $scale, $progression->[0]);
    print "$i. $named, $progression->[1]\n";
}
