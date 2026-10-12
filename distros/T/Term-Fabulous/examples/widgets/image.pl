#!/usr/bin/env perl

# Term::Fabulous::Widget::Image: a 16x16 PNG in three widgets of the same
# fixed size, one per fit: none (the default) keeps its natural size,
# contain scales it to fit and keeps its proportions, stretch fills the
# widget. Three more, smaller than the picture, show the fits there:
# none cuts it, contain shrinks it and keeps its proportions, stretch
# shrinks it to fill the widget. Without Imager installed, each image
# shows a notice instead.
# Ctrl+C quits.
#
#     perl examples/widgets/image.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Image;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $circle = "$FindBin::Bin/../images/rainbow_circle.png";

# An image of a fixed size in cells, inside its border, with the fit and
# the size as the caption above it.
sub framed ( $fit, $columns, $rows ) {
	my $panel = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
	$panel->add_child(
		Term::Fabulous::Widget::Text->new( text => $fit ),
		Term::Fabulous::Widget::Text->new( text => "fixed ${columns}x$rows" ),
		Term::Fabulous::Widget::Image->new(
			file     => $circle,
			fit      => $fit =~ s/ .*//r,
			bordered => 1,
			layout   => { sizing => { width => sizing_fixed( $columns + 2 ), height => sizing_fixed( $rows + 2 ) } },
		),
	);
	return $panel;
}

# The three fits again, in widgets smaller than the picture, one below
# the other.
sub small_column () {
	my $column = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 1 } );
	$column->add_child( map { framed( $_, 12, 4 ) } 'none (default)', 'contain', 'stretch' );
	return $column;
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 3,
	},
);

$root->add_child(
	framed( 'none (default)', 32, 24 ),
	framed( 'contain',        32, 24 ),
	framed( 'stretch',        32, 24 ),
	small_column(),
);

my $ui = Term::Fabulous->new( width => 129, height => 30, root => $root );
$ui->run;
