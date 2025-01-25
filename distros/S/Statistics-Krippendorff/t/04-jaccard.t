#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Krippendorff;

use Test2::V0;

my $sk1 = 'Statistics::Krippendorff'->new(
    units => [['a,b', 'b,a'], ['b,c', 'c,b'], ['e,f', 'f,e'],
              ['x', 'b,a'],['a', 'a,b']],
    delta => \&Statistics::Krippendorff::delta_jaccard
);

my $alpha1 = $sk1->alpha;

my $sk2 = 'Statistics::Krippendorff'->new(
    units => [['a,b', 'a,b'], ['b,c', 'b,c'], ['e,f', 'e,f'],
              ['b,a', 'x'], ['a', 'b,a']],
    delta => \&Statistics::Krippendorff::delta_jaccard
);
is $sk2->alpha, float($alpha1, precision => 8),
    q(Order inside values doesn't matter);

done_testing;
