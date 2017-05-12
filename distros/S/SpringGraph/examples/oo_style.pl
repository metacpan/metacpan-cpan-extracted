#!/usr/bin/perl -w

#####################
# object oriented way

use strict;

use SpringGraph;

my $graph = new SpringGraph;
my $filename = 'testgraph_oo.png';

$graph->add_node('london', label=>'London (Waterloo)');
$graph->add_node('paris', label =>'Paris (Garde du Norde)');
$graph->add_node('brussels',label => "Brussels");

$graph->add_edge(london=>'paris');
#$graph->add_edge(paris=>'brussels');

warn "..getting as png\n";

$graph->as_png($filename);


warn "all done\n";
