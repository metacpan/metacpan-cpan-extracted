#!/usr/bin/env perl
use warnings;
use strict;
use PDL;
use PDL::IO::Matlab;
use PDL::NiceSlice;

# test for memory leak.
foreach (0..1000) {
    my $f1 = 'Rep_Carlo_90nm.mat';
    my $mat1 = PDL::IO::Matlab->new($f1, '<');
    my $x = $mat1->read_next;
#    print $x->shape, "\n";
    $mat1->close;
}

print "sleeping...\n";
sleep(100);
