#!/usr/bin/env perl

require 5.010;
use strict;
use feature 'say';
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

my $d = runif(n => 3, min => 0, max => 1);
say 'runif:';
p $d;
$d = runif(n => 3, min => 0, max => 1);
p $d;
$d = runif(99);
p $d;

