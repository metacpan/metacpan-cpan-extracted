#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

my $q = quantile('x' => [0..99], probs => [0,1]);
p $q;
$q = quantile([0..99], probs => [0,1]);
p $q;
