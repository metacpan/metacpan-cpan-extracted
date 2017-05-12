#!/usr/bin/perl


# use strict;
require Neuron;

print "1..1\n";

my $layer1 = NLayer -> new(10, 20);
my $layer2 = NLayer -> new(1, 10);

my @d1 = (0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

$layer1 -> compute(@d1);
# $layer1 -> show_out;


my @d2 = ();

for(my $i = 0; $i < 10; $i ++) {
    $d2[$i] = $layer1 -> neuron($i) -> out;
}

$layer2 -> compute(@d2);
# print "* "; $layer2 -> show_out;

print "ok 1\n";



