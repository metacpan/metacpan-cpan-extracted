#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Devel::Confess;
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Stats::LikeR;

my $table = read_table(
	't/HepatitisCdata.csv',
	'output.type' => 'hoh',
	filter => {
		Sex => sub {$_ eq 'f'}
	}
);
p $table;
