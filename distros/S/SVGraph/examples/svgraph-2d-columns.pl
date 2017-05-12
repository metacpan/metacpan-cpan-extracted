#!/bin/perl
use SVGraph::2D::columns;
use strict;

my $graph=SVGraph::2D::columns->new(
  title => "My graph",
  type => "normal",
  x => 500,
  y => 300,
  show_legend => 1,
  show_data => 1,
  show_data_background =>1,
  grid_y_scale_maximum => 70.00,
  show_grid_x => 1
  );

# adding two columns
my %columns;
$columns{first}=$graph->addColumn(title=>"first"); 
$columns{second}=$graph->addColumn(title=>"second");

# adding rows and labels
$graph->addRowLabel('1');
$graph->addRowLabel('2');

# data for graph
$columns{first}->addData('1',14);
$columns{second}->addData('2',50);

$graph->addValueMark(20,front => 1, color => 'blue', 
                    right => 1, show_label_text => 'minimum', show_label => 1);

# print svg file
print $graph->prepare;
