#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my @d1 = ();

my($i,$j) = (0,0);
while(<>){
  last if $i >= 15;
  chomp;
  my @cols = split /\t/;
  $j = 0;
  foreach my $c (@cols){
    last if $j >= 15;
    next if $c =~ /nan/;
    $c = int($c);
warn "$c @ $j,$i";
    push @d1, SVG::Graph::Data::Datum->new(x=>$j,y=>$i,z=>$c);
    $j++;
  }

  $i++;
}

my $graph = SVG::Graph->new(width=>600,height=>600,margin=>30);

my $frame0 = $graph->add_frame;
my $frame1 = $frame0->add_frame;

#for(1..int(rand(10)+1)){push @d1, SVG::Graph::Data::Datum->new(x=>int(rand(50)),y=>int(rand(50)),z=>int(rand(10))+1);}
#for my $i (1..20){
#  for my $j (1..20){
#    push @d1, SVG::Graph::Data::Datum->new(x=>$i,y=>$j,z=>int(rand(255)));
#  }
#}

my $data1 = SVG::Graph::Data->new(data => \@d1);

$frame1->add_data($data1);

$frame0->add_glyph('axis','stroke'=>'black','stroke-width'=>2);
#$frame0->add_glyph('scatter', 'fill'=>'grey','fill-opacity'=>0.3);
$frame1->add_glyph('heatmap',  'fill'=>'yellow','fill-opacity'=>0,stroke=>'black',rgb_h=>[255,255,0],rgb_m=>[255,255,255],rgb_l=>[0,0,255]);


print $graph->draw;
