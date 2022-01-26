#!/bin/env perl
use strict;
use warnings;
use List::Util qw/shuffle/;
use Set::Object 1.35 qw/set/;
my @list = shuffle(1..1000);
use Benchmark 'cmpthese';

my $lil_set = set(@list);
my $x = 0;
cmpthese(-3,
         {
           'Fast set->members' =>
             sub {
               foreach my $item ($lil_set->members()) {
                 $x += $item;
                 $x += $item;
                 $x += $item;
                 $x += $item;
                 $x += $item;
               }},
           'Slow @$set' => 
             sub {
               foreach my $item (@{$lil_set}) {
                 $x += $item;
                 $x += $item;
                 $x += $item;
                 $x += $item;
                 $x += $item;
               }}});
__END__
