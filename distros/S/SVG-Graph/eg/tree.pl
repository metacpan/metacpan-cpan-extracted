#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Tree;

my %fill = (
	   1=>'red',
	   2=>'orange',
	   3=>'yellow',
	   4=>'green',
	   5=>'blue',
	   6=>'indigo',
	   7=>'violet',
	   );

my $graph = SVG::Graph->new(width=>600,height=>600,margin=>30);

my $group0 = $graph->add_frame;

my $tree = SVG::Graph::Data::Tree->new;

$group0->add_data($tree);

my $root = $tree->root;
$root->branch_length(int(rand(10)+1));

my @nodes = ();
for my $c (0..20){
  my $node = $tree->new_node(branch_length=>int(rand(10)+2),stroke=>$fill{int(rand(7)+1)},'stroke-width'=>int(rand(5)+1));

  if($c < 2){
    $root->add_daughter($node);
  } else {
    my $rand_parent = $nodes[int(rand($#nodes))];
    $rand_parent->add_daughter($node);
  }

  push @nodes, $node;
}

$group0->add_glyph('tree', stroke=>'black','stroke-width'=>2);
print $graph->draw;
