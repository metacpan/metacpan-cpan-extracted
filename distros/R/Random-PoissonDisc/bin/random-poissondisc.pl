#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Random::PoissonDisc;

GetOptions(
    'r:s' => \my $r,
    'dimensions|d:s' => \my @dimensions,
);

$r ||= 10;

if (! @dimensions) {
    @dimensions = (100,100);
};

@dimensions = map { split /,/ } @dimensions;

my $points = Random::PoissonDisc->points(
    dimensions => \@dimensions,
    r => $r,
);

for (@$points) {
    print join( "\t", @$_), "\n";
};