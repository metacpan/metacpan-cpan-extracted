#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Tree;

my $graph = SVG::Graph->new(width=>1600,height=>1000,margin=>30);

my $group0 = $graph->add_group;

my $tree = SVG::Graph::Data::Tree->new;

$tree->read_file('-file'=>'euk.newick','-format'=>'newick');
$group0->add_data($tree);

$group0->add_glyph('tree', stroke=>'black','stroke-width'=>2,'font-size'=>'10px');
print $graph->draw;
