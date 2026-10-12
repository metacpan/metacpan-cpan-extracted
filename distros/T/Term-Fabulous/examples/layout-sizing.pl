#!/usr/bin/env perl

# The sizing rules side by side: every row is a track as wide as the
# terminal, and the colored boxes in it are sized with the rule shown on
# the left. The labels share a width group, so the tracks line up.
# Ctrl+C quits.
#
#     perl examples/layout-sizing.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_fit sizing_grow sizing_fixed sizing_percent CLAY_TOP_TO_BOTTOM);

my @COLORS = ( [ 97, 175, 239, 255 ], [ 152, 195, 121, 255 ], [ 229, 192, 123, 255 ] );

# A colored box of the given width, labeled with its rule.
sub sample ( $caption, $width, $color ) {
	my $box = Term::Fabulous::Widget::Box->new(
		background_color => $color,
		layout           => { sizing => { width => $width }, padding => { left => 1, right => 1 } },
	);
	return $box->add_child( Term::Fabulous::Widget::Text->new( text => $caption, text_color => [ 20, 25, 35, 255 ] ) );
}

# A label and a track that holds the samples.
sub row ( $label, @samples ) {
	my $name = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$name->add_child( Term::Fabulous::Widget::Text->new( text => $label, text_color => [ 220, 220, 220, 255 ] ) );

	my $track = Term::Fabulous::Widget::Box->new(
		background_color => [ 40, 46, 64, 255 ],
		layout           => { sizing => { width => sizing_grow() } },
	);
	$track->add_child(@samples);

	my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 2 } );
	return $row->add_child( $name, $track );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

$root->add_child(
	row( 'sizing_fit()',        sample( 'as wide as this text', sizing_fit(),         $COLORS[0] ) ),
	row( 'sizing_fit(30)',      sample( 'at least 30',          sizing_fit(30),       $COLORS[0] ) ),
	row( 'sizing_fixed(20)',    sample( '20 columns',           sizing_fixed(20),     $COLORS[1] ) ),
	row( 'sizing_percent(0.5)', sample( 'half of the track',    sizing_percent(0.5),  $COLORS[1] ) ),
	row( 'sizing_grow()',       sample( 'the whole track',      sizing_grow(),        $COLORS[2] ) ),
	row( 'sizing_grow(0, 30)',  sample( 'grows up to 30',       sizing_grow( 0, 30 ), $COLORS[2] ) ),
	row( 'fixed(20) + grow()',  sample( '20 columns',           sizing_fixed(20),     $COLORS[1] ), sample( 'the rest',   sizing_grow(), $COLORS[2] ) ),
	row( 'grow() + grow()',     sample( 'one half',             sizing_grow(),        $COLORS[2] ), sample( 'other half', sizing_grow(), $COLORS[0] ) ),
);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
