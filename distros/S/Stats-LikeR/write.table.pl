#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Devel::Confess;
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Stats::LikeR;

my %hoa = (
	a => [1..3],
	b => [4..9],
	c => [0..5]
);
write_table(
	\%hoa, '/tmp/write.cols.tsv',
	'col.names' => [qw(a b)],
	'row.names' => false
);
