#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my @d1 = ();

my $head = <>;
chomp $head;
my @head = split /\t/, $head;
shift @head;

my($i,$j) = (1,1);
while(<>){
  chomp;
  my @cols = split /\t/;
  shift @cols;

  $j = 1;
  foreach my $c (@cols){
    $c = int($c);
    $c = 200 if $c eq 'nan';
#    $c = 200 if $c == 0;

    my $logc = log($c > 0 ? $c : 0.000001) / log(2);
#    $logc = 10 if $logc > 10;
#    $logc = 3 if $logc < 3;
    $logc = undef if $c == 0;

#warn $c , "\t", $logc;

    push @d1, SVG::Graph::Data::Datum->new(x=>$j,y=>$i,z=>$logc);
    $j++;
  }

  $i++;
}

my $svg = SVG->new(width=>850,height=>850);
my $graph = SVG::Graph->new(svg=>$svg,xoffset=>0,yoffset=>0,width=>800,height=>700,margin=>30);

my $frame0 = $graph->add_frame;
my $frame1 = $frame0->add_frame;

my $data1 = SVG::Graph::Data->new(data => \@d1);

$frame1->add_data($data1);

$frame0->add_glyph('axis','stroke'=>'black','stroke-width'=>2,'x_absolute_ticks'=>1,x_intertick_labels=>\@head);
$frame1->add_glyph('heatmap',rgb_h=>[255,0,0],rgb_m=>[0,0,0],rgb_l=>[0,255,0]);

print $graph->draw;
