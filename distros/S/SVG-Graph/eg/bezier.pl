#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my $graph = SVG::Graph->new(width=>600,height=>600,margin=>30);

my $frame0 = $graph->add_frame;
my $frame1 = $frame0->add_frame;
my $frame2 = $frame0->add_frame;

my @d1 = ();
my @d2 = ();

for(1..int(rand(30)+1)){push @d1, SVG::Graph::Data::Datum->new(x=>int(rand(50)),y=>int(rand(50)),z=>int(rand(10))+1);}
for(1..int(rand(10)+3)){push @d2, SVG::Graph::Data::Datum->new(x=>int(rand(50)),y=>int(rand(10)),z=>int(rand(10))+1);}

my $data1 = SVG::Graph::Data->new(data => \@d1);
my $data2 = SVG::Graph::Data->new(data => \@d2);

$frame1->add_data($data1);
$frame2->add_data($data2);

$frame0->add_glyph('axis',x_fractional_ticks=>4,y_fractional_ticks=>6,'stroke'=>'black','stroke-width'=>2);
$frame0->add_glyph('scatter', 'fill'=>'blue','fill-opacity'=>0.3);
$frame1->add_glyph('bubble',  'fill'=>'yellow','fill-opacity'=>0.3,stroke=>'yellow');
$frame1->add_glyph('bezier',  'fill'=>'yellow','fill-opacity'=>0.0,stroke=>'orange');
$frame2->add_glyph('bubble',  'fill'=>'red','fill-opacity'=>0.3,stroke=>'red');
$frame2->add_glyph('bezier',  'fill'=>'red','fill-opacity'=>0.0,stroke=>'red');


print $graph->draw;
