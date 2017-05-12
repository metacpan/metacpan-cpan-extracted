#!/usr/bin/perl
use strict;
use warnings;

# run this example using plackup -r examples/svg.psgi

use SVG;
 
my $app = sub {
	my $svg = SVG->new(
		width  => 200,
		height => 200,
	);
	$svg->title()->cdata('I am a title');

	# add a circle
	$svg->circle(
		cx => 100,
		cy => 100,
		r  => 50,
		id => 'circle_in_group_y',
		style => {
			fill => '#FF0000',
		}
	);

	return [
		'200',
		[ 'Content-Type' => 'image/svg+xml' ],
		[ $svg->xmlify ],
	];
};

