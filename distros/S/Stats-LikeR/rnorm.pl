#!/usr/bin/env perl

require 5.010;
use strict;
use feature 'say';
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

my $d = rnorm(n => 9);
say 'rnorm:';
p $d;
$d = rnorm(n => 3);
p $d;
$d = rnorm(99);
p $d;

