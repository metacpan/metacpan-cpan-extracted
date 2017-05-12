#!/bin/env perl

use strict;
use RRD::Simple 1.44;
 
my $rrd = RRD::Simple->new( file => "$ENV{HOME}/webroot/www/rrd.me.uk/data/boromir.rbsov.tfb.net/mem_usage.rrd" );
 
$rrd->graph(
		periods => [ qw( month weekly ) ],
		destination => "$ENV{HOME}/webroot/www/bb-207-42-158-85.fallbr.tfb.net/D:/",
		title => "Memory Utilisation",
		base => 1024,
		vertical_label => "bytes",
		sources => [ qw(Total Used) ],
		source_drawtypes => [ qw(AREA LINE1) ],
		source_colours => "dddddd 0000dd",
		lower_limit => 0,
		rigid => "",
		"VDEF:D=Used,LSLSLOPE" => "",
		"VDEF:H=Used,LSLINT" => "",
		"VDEF:F=Used,LSLCORREL" => "",
		"CDEF:Proj=Used,POP,D,COUNT,*,H,+" => "",
		"LINE1:Proj#dd0000: Projection" => "",
		"SHIFT:Total:-604800" => "",
		"SHIFT:Used:-604800" => "",
	);

