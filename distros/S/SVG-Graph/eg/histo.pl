#!/usr/bin/perl

use strict;
use Statistics::Descriptive;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

my %stat;

my $graph = SVG::Graph->new(width => 1000, height => 800, margin => 40);
my $parentgroup = $graph->add_group;
my $statgroup = $parentgroup->add_group;
my $bargroup = $parentgroup->add_group;

my @data;
my $ymax = undef;
my $stat = Statistics::Descriptive::Full->new;
while(<>){
	chomp;
	if(/^#stat:/){
		process_stat($_);
		next;
	}
	my($x,$y) = split /\s+/;
	$ymax = $y > $ymax ? $y : $ymax;
	$stat->add_data($x);
	push @data, SVG::Graph::Data::Datum->new(x => $x , y => $y);
}

$parentgroup->add_glyph('axis');

warn $stat{mean};

my @statdata = 	(
			SVG::Graph::Data::Datum->new(x => $stat->min,  y => 0),

#			SVG::Graph::Data::Datum->new(x => $stat{mean}, y => $ymax),
#			SVG::Graph::Data::Datum->new(x => $stat{mean} - $stat{standard_deviation}, y => $ymax),
#			SVG::Graph::Data::Datum->new(x => $stat{mean} + $stat{standard_deviation}, y => 0),

			SVG::Graph::Data::Datum->new(x => $stat{median}, y => $ymax),
			SVG::Graph::Data::Datum->new(x => $stat{quartile1}, y => $ymax),
			SVG::Graph::Data::Datum->new(x => $stat{quartile3}, y => 0),

			SVG::Graph::Data::Datum->new(x => $stat->max,  y => 0),

		);
$statgroup->add_data(SVG::Graph::Data->new(data => \@statdata));
$statgroup->add_glyph('barflex', 'stroke' => 'black', 'fill' => 'black', 'stroke-opacity' => 1.0, 'fill-opacity' => 0.4 );

$bargroup->add_data(SVG::Graph::Data->new(data => \@data));
$bargroup->add_glyph('bar', 'stroke' => 'red', 'fill' => 'red', 'stroke-opacity' => 1.0, 'fill-opacity' => 0.8 );

print $graph->draw;

sub process_stat {
	my $line = shift;
	my($name,$value) = $line =~ /^#stat:(\S+)\t(\S+)$/;
	$stat{$name} = $value;
}
