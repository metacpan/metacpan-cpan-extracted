#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Devel::Confess;
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Stats::LikeR;

my $h = wilcox_test(
	[1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
	[0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
);
p $h;

