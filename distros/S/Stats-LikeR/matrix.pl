#!/usr/bin/env perl

require 5.010;
use strict;
use feature 'say';
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

my $d = matrix(rnorm(32000), 1000, 32);
my $mat1 = matrix(
	data => [1..6],
	nrow => 2
);
p $mat1;
