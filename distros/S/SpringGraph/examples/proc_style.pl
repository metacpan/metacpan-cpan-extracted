#!/usr/bin/perl -w

################
# procedural way

use strict;
use SpringGraph qw(calculate_graph draw_graph);

warn "drawing image - procedural\n";

my %node = (
	    london => { label => 'London (Waterloo)'},
	    paris => { label => 'Paris' },
	    brussels => { label => 'Brussels'},
	   );
my %link = (
	    london => { paris => {dir=>1} }, # arrow
	    paris => { brussels => {style=>'dashed'} }, # no arror
	   );
my $scale = 1;

my $graph = calculate_graph(\%node,\%link);

my $filename = 'testgraph_proc.png';

warn "..getting as png\n";

draw_graph($filename,\%node,\%link);

warn "all done\n";
