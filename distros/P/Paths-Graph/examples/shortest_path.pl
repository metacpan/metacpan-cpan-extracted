#!/usr/bin/perl

my %graph = (
                A => {B=>1,C=>4,G=>2},
                B => {A=>1,C=>2,D=>1,E=>5,F=>9,G=>8},
                C => {A=>4,B=>2,F=>6},
                D => {B=>1,E=>7,G=>3},
                E => {B=>5,D=>7,F=>2},
                F => {B=>9,C=>6,E=>2},
                G => {A=>2,B=>8,D=>3},
);
use Paths::Graph;
my $obj = Paths::Graph->new(-origin=>"A",-destiny=>"C",-graph=>\%graph);
my @paths = $obj->shortest_path();
for my $path (@paths) {
	print "Shortest Path:" . join ("->" , @{$path}) . " Cost:". $obj->get_path_cost(@{$path});
	print "\n";
}
