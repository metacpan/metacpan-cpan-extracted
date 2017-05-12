#!/usr/bin/perl
use strict;

my $attributes = shift @ARGV;
my $rows = shift @ARGV;
my $percent_per_entity = shift @ARGV or die "usage $0 <attributes> <rows> <sparseness(1-100)>\n";
my @fields = ( map { sprintf "attribute\_%03d", $_ } (1..$attributes) );

srand(100);
for my $entity (1..$rows) {
    for my $a (0..$#fields) {
        next unless $percent_per_entity > int rand 100;
        my $value = int rand 500;
        print "$entity,$fields[$a],$value\n";
    }
}

