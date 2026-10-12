#!/usr/bin/env perl

# Term::Fabulous borders beyond a single style: a border on some sides
# only, a style per side, padding inside a border, a Hidden side, two
# boxes that share one line through border_corners, and a border drawn
# on the parent's background with outer_border_sides. Ctrl+C quits.
#
#     perl examples/border-options.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $style        = 'Term::Fabulous::Enum::BorderStyle';
my $border_color = [ 140, 180, 230, 255 ];
my $panel_color  = [ 35,  42,  60,  255 ];
my $text_color   = [ 230, 230, 230, 255 ];

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

sub text ($string) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $text_color );
}

# A panel with a border made of the given parameters and a text inside.
sub sample ( $string, %border ) {
	my $box = Term::Fabulous::Widget::Box->new(
		background_color => $panel_color,
		border_color     => $border_color,
		layout           => { sizing => { width => sizing_fixed(22) } },
		%border,
	);
	$box->add_child( text($string) );
	return $box;
}

sub row (@widgets) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 3 } );
	$row->add_child(@widgets);
	$root->add_child($row);
	return;
}

row(
	sample( "bordered\n{ left, top }", bordered => { left => 1, top => 1 }, border_style => $style->Solid ),
	sample(
		"Solid, with a\nDouble top and a\nThick left side",
		bordered          => 1,
		border_style      => $style->Solid,
		border_style_top  => $style->Double,
		border_style_left => $style->Thick,
	),
	sample(
		"Round, with a\ncell of padding\ninside the border",
		bordered     => 1,
		border_style => $style->Round,
		layout       => { sizing => { width => sizing_fixed(22) }, padding => { left => 1, right => 1, top => 1, bottom => 1 } },
	),
);

# Two boxes that share one line: the upper one has no bottom side, and the
# lower one joins its top corners to the sides of the upper one.
my $solid  = $style->Solid;
my $joined = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
$joined->add_child(
	sample( "Title box", bordered => { left => 1, right => 1, top => 1 }, border_style => $solid ),
	sample(
		"Body box joined\nby border_corners",
		bordered       => 1,
		border_style   => $solid,
		border_corners => {
			top_left  => $style->junction( up => $solid, right => $solid, down => $solid ),    # ├
			top_right => $style->junction( up => $solid, left  => $solid, down => $solid ),    # ┤
		},
	),
);

row(
	sample( "Round, with a\nHidden bottom side", bordered => 1, border_style => $style->Round, border_style_bottom => $style->Hidden ),
	$joined,
	sample( "outer_border_sides\non all four sides", bordered => 1, border_style => $style->Round, outer_border_sides => [qw(top right bottom left)] ),
);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
