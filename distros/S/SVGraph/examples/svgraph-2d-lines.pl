#!/bin/perl
use strict;
use SVGraph::2D::lines;

my $graph=SVGraph::2D::lines->new(
 title => "My graph",
 type => "normal/percentage",
 x => 500,
 y => 300,
 show_lines => 1,
 show_points => 1,
 grid_y_main_lines => 0,
 show_label_textsize => 20,
 show_legend => 1,
 show_data => 1,
 show_data_background => 1,
 show_grid_x => 0
);

# two columns -> two lines in the graph
my %columns;
$columns{first}=$graph->addColumn(title=>"first", show_line=>1);
$columns{second}=$graph->addColumn(title=>"second", show_line=>1);

$graph->addRowLabel('1');
$graph->addRowLabel('2');
$graph->addRowLabel('3');

$graph->addValueMark(20,front => 1, color => 'blue', right => 1, 
                     show_label_text => 'something', show_label => 1);
# data for graph
$columns{first}->addData('1',30);
$columns{first}->addData('2',60);
$columns{first}->addData('3',50);
$columns{second}->addData('1',20);
$columns{second}->addData('2',0);
$columns{second}->addData('3',70);

# creates svg file
print $graph->prepare;
