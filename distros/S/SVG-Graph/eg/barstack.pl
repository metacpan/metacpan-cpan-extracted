#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my $graph = SVG::Graph->new(width=>800,height=>800,margin=>30);

my $frame0 = $graph->add_frame;
$frame0->stack(1);
my $frame1 = $frame0->add_frame;
my $frame2 = $frame0->add_frame;
my $frame3 = $frame0->add_frame;
my $frame4 = $frame0->add_frame;

my @d1 = ();
my @d2 = ();
my @d3 = ();
my @d4 = ();

for(1..10){push @d1, SVG::Graph::Data::Datum->new(x=>$_,y=>int(rand(10)));}
for(1..10){push @d2, SVG::Graph::Data::Datum->new(x=>$_,y=>int(rand(10)));}
for(1..10){push @d3, SVG::Graph::Data::Datum->new(x=>$_,y=>int(rand(10)));}
for(1..10){push @d4, SVG::Graph::Data::Datum->new(x=>$_,y=>int(rand(10)));}

my $data1 = SVG::Graph::Data->new(data => \@d1);
my $data2 = SVG::Graph::Data->new(data => \@d2);
my $data3 = SVG::Graph::Data->new(data => \@d3);
my $data4 = SVG::Graph::Data->new(data => \@d4);

$frame1->add_data($data1);
$frame2->add_data($data2);
$frame3->add_data($data3);
$frame4->add_data($data4);

$frame0->add_glyph('axis',x_absolute_ticks=>1,'stroke'=>'black','stroke-width'=>2);

$frame1->add_glyph('bar',  'fill'=>'red','fill-opacity'=>0.5,stroke=>'red');
$frame2->add_glyph('bar',  'fill'=>'blue','fill-opacity'=>0.5,stroke=>'blue');
$frame3->add_glyph('bar',  'fill'=>'yellow','fill-opacity'=>0.5,stroke=>'yellow');
$frame4->add_glyph('bar',  'fill'=>'green','fill-opacity'=>0.5,stroke=>'green');

print $graph->draw;
