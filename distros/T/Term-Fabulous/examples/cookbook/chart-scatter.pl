#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScatterPlot;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# Measurements of three species: [ x, y ] pairs, both numbers.
srand 11;

sub flowers ( $count, $length, $width, $slope ) {
	return map {
		my $petal = $length + ( rand() - 0.5 ) * 2;
		[ $petal, $width + $slope * ( $petal - $length ) + ( rand() - 0.5 ) * 0.7 ];
	} 1 .. $count;
}

my $plot = Term::Fabulous::Widget::ScatterPlot->new(
	title  => 'Petal size',
	x_axis => { title => 'length (cm)', grid => 'dotted' },
	y_axis => { title => 'width (cm)' },
	series => [
		{ name => 'Setosa',     data => [ flowers( 15, 1.5, 0.4, 0.1 ) ] },
		{ name => 'Versicolor', data => [ flowers( 15, 4.3, 1.3, 0.4 ) ], trend => 1 },
		{ name => 'Virginica',  data => [ flowers( 15, 5.6, 2.0, 0.3 ) ], trend => 1, point => "\x{25C6}" },
	],
);
$root->add_child($plot);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
