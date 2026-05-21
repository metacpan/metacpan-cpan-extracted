#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

my $d = runif(n => 3, min => 0, max => 1);
say 'runif:';
p $d;
$d = runif(99);
p $d;
#--------------
$d = rnorm(mean => 5, n => 3, sd => 2);
say 'rnorm:';
p $d;
say 'rnorm with 9 elements:';
$d = rnorm(9);
p $d;
$d = rnorm(9, 1);
p $d;
#--------------
$d = rbinom(n => 3, size => 4, prob => 0.5);
say 'rbinom:';
p $d;
#--------------

