#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my $graph = SVG::Graph->new(width=>600,height=>600,margin=>30);

my $frame0 = $graph->add_frame;
$frame0->stack(1);
my $frame1 = $frame0->add_frame;

my @d1 = ();

push @d1, SVG::Graph::Data::Datum->new(x=>1,y=>2.0,label=>'A');
push @d1, SVG::Graph::Data::Datum->new(x=>2,y=>1.0,label=>'T');
#push @d1, SVG::Graph::Data::Datum->new(x=>3,y=>0.5,label=>'G');
#push @d1, SVG::Graph::Data::Datum->new(x=>4,y=>0.0,label=>'C');
#push @d1, SVG::Graph::Data::Datum->new(x=>5,y=>0.1,label=>'A');
push @d1, SVG::Graph::Data::Datum->new(x=>6,y=>1.5,label=>'T');
#push @d1, SVG::Graph::Data::Datum->new(x=>7,y=>0.3,label=>'C');
#push @d1, SVG::Graph::Data::Datum->new(x=>8,y=>0.7,label=>'A');
push @d1, SVG::Graph::Data::Datum->new(x=>9,y=>1.2,label=>'G');


my $data1 = SVG::Graph::Data->new(data => \@d1);

$frame1->add_data($data1);

$frame0->add_glyph('axis',x_absolute_ticks=>1,y_absolute_ticks=>0.5,'stroke'=>'black','stroke-width'=>2);
$frame0->add_glyph('pictogram', color => {A => 'red', T => 'green', G => 'blue', C => 'orange'});

print $graph->draw;
