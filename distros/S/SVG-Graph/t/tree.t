use strict;

BEGIN {
  eval { require Test; };
  if($@){
    use lib 't';
  }
  use Test;
  plan test => 11;
}

use SVG::Graph;
ok(1);
use SVG::Graph::Data;
ok(2);
use SVG::Graph::Data::Tree;
ok(3);

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
ok(4);

my $group = $graph->add_frame;
ok(5);

my $tree = SVG::Graph::Data::Tree->new;
ok(6);

$group->add_data($tree);
ok(7);

my $root = $tree->root;
ok(8);
$root->branch_length(10);
ok(9);

my @nodes = ();
for my $c (0..20){
  my $node = $tree->new_node(branch_length=>10,stroke=>$fill{5},'stroke-width'=>3);

  if($c < 2){
    $root->add_daughter($node);
  } else {
    my $rand_parent = $nodes[$c - 1];
    $rand_parent->add_daughter($node);
  }

  push @nodes, $node;
}

$group->add_glyph('tree', stroke=>'black','stroke-width'=>2);
ok(10);

$graph->draw;
ok(11);
