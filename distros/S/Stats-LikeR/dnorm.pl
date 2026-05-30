#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

foreach my $x (-5..5) {
	printf("$x => %.15f\n", dnorm($x));
}
my $x = dnorm([1,2,3]);
$x = dnorm(0, mean => 0, sd => 2, 'log' => 0);

