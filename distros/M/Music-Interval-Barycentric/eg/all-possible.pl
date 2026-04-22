#!/usr/bin/env perl

# Show all possible chords sorted by their evenness
use strict;
use warnings;

use Algorithm::Combinatorics 'combinations';
use Music::Interval::Barycentric;

# Pitch class triads
my $i_iter = combinations([0 .. 11], 3);
#my $i_iter = combinations([qw/ 0 2 4 5 7 9 11 /], 3);

# Collect metrics
my %data;
while (my $i = $i_iter->next) {
    $data{"@$i"} = evenness_index($i);
}

my $c_field = length(keys %data);

# Show sorted metrics
my $count = 0;
for my $d (sort { $data{$a} <=> $data{$b} || $a cmp $b } keys %data) {
    $count++;

    printf "%*d. %d %2d %2d => %.14f\n",
        $c_field, $count, (split / /, $d), $data{$d};
}
