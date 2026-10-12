#!/usr/bin/env perl

# Term::Fabulous::Widget::Sixel: a 480x320 PNG of the Mandelbrot set in
# sixel graphics, in three widgets of the same fixed size, one per fit:
# none (the default) keeps its natural size and cuts it on every side,
# contain scales it to fit and keeps its proportions, stretch fills the
# widget. The terminal draws the pictures in its own pixels. Without
# Imager and Imager::File::SIXEL installed, or in a terminal without
# sixel graphics, each widget shows a notice instead.
# Ctrl+C quits.
#
#     perl examples/widgets/sixel.pl

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
use Term::Fabulous::Widget::Sixel;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $fractal = "$FindBin::Bin/../images/mandelbrot.png";

# A picture of a fixed size in cells, inside its border, with the fit
# and the size as the caption above it.
sub framed ( $fit, $columns, $rows ) {
	my $panel = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
	$panel->add_child(
		Term::Fabulous::Widget::Text->new( text => $fit ),
		Term::Fabulous::Widget::Text->new( text => "fixed ${columns}x$rows" ),
		Term::Fabulous::Widget::Sixel->new(
			file     => $fractal,
			fit      => $fit =~ s/ .*//r,
			bordered => 1,
			layout   => { sizing => { width => sizing_fixed( $columns + 2 ), height => sizing_fixed( $rows + 2 ) } },
		),
	);
	return $panel;
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 3,
	},
);

$root->add_child(
	framed( 'none (default)', 28, 10 ),
	framed( 'contain',        28, 10 ),
	framed( 'stretch',        28, 10 ),
);

my $ui = Term::Fabulous->new( width => 100, height => 17, root => $root );
$ui->run;
