#!/usr/bin/perl

use strict;
use Data::Dumper;
use SVG::Graph;
use SVG::Graph::Group;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my $graph = SVG::Graph->new(width=>600,height=>600,margin=>30);

my $frame1 = $graph->add_frame;
my $frame2 = $graph->add_frame;

my $data1 = SVG::Graph::Data->new(data => [
						SVG::Graph::Data::Datum->new(x=>10,y=>10),
						SVG::Graph::Data::Datum->new(x=>11,y=>11),
					  ]);

my $data2 = SVG::Graph::Data->new(data => [
						SVG::Graph::Data::Datum->new(x=>20,y=>20),
						SVG::Graph::Data::Datum->new(x=>30,y=>30),
					  ]);

my $data3 = SVG::Graph::Data->new(data => [
						SVG::Graph::Data::Datum->new(x=>25,y=>25),
						SVG::Graph::Data::Datum->new(x=>25,y=>25),
						SVG::Graph::Data::Datum->new(x=>25,y=>25),
#						SVG::Graph::Data::Datum->new(x=>40,y=>40),
						SVG::Graph::Data::Datum->new(x=>50,y=>50),
						SVG::Graph::Data::Datum->new(x=>80,y=>80),
#						SVG::Graph::Data::Datum->new(x=>60,y=>60),
#						SVG::Graph::Data::Datum->new(x=>70,y=>70),
#						SVG::Graph::Data::Datum->new(x=>80,y=>80),
					  ]);

$frame1->add_data($data1);
$frame1->add_frame($frame2);
#$frame2->add_data($data2);
$frame2->add_data($data3);

$frame2->add_glyph('wedge');

$frame1->draw;
$frame2->draw;


print $graph->svg->xmlify;

#my $xml = $frame2->draw;

#print $xml,"\n";

#print Dumper($frame2), "\n";
#print $frame1->xmin, "\n";
#print $frame1->xmax, "\n";
