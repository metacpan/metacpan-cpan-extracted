#!/usr/bin/env perl

# Term::Fabulous colors: one orange written in six formats, colors
# derived with lighten, darken and blend, translucent backgrounds over a
# light panel, and the terminal's default colors (alpha 0). Ctrl+C quits.
#
#     perl examples/colors.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Color;
use Term::Fabulous::Enum::WebColor;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $label_color = [ 150, 160, 180, 255 ];
my $dark_text   = [ 20,  20,  20,  255 ];
my $light_text  = [ 240, 240, 240, 255 ];

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A row with a label in a column of its own and the given widgets.
sub color_row ( $label, @widgets ) {
	my $label_box = Term::Fabulous::Widget::Box->new( width_group => 1, layout => { padding => { right => 1 } } );
	$label_box->add_child( Term::Fabulous::Widget::Text->new( text => $label, text_color => $label_color ) );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1 } );
	$row->add_child( $label_box, @widgets );
	$root->add_child($row);
	return;
}

# A box of the given background color with a caption in it.
sub swatch ( $color, $caption, $caption_color = $dark_text ) {
	my $box = Term::Fabulous::Widget::Box->new(
		background_color => $color,
		layout           => { sizing => { width => sizing_fixed(10) } },
	);
	$box->add_child( Term::Fabulous::Widget::Text->new( text => $caption, text_color => $caption_color ) );
	return $box;
}

color_row(
	'formats',
	swatch( '#ff8800',                                  "'#ff8800'" ),
	swatch( 'rgb(255, 136, 0)',                         'rgb()' ),
	swatch( 'hsl(32, 100%, 50%)',                       'hsl()' ),
	swatch( [ 255, 136, 0 ],                            '[r, g, b]' ),
	swatch( 0xFF8800,                                   '0xFF8800' ),
	swatch( Term::Fabulous::Enum::WebColor->DarkOrange, 'DarkOrange' ),
);

my $blue = Term::Fabulous::Color->hex('#3b82f6');
color_row( 'darken', swatch( $blue->darken(0.3), '0.3', $light_text ), swatch( $blue->darken(0.15), '0.15', $light_text ), swatch( $blue, '#3b82f6' ) );
color_row( 'lighten', swatch( $blue, '#3b82f6' ), swatch( $blue->lighten(0.15), '0.15' ), swatch( $blue->lighten(0.3), '0.3' ) );

my $white = Term::Fabulous::Enum::WebColor->White;
color_row( 'blend', map { swatch( $blue->blend( $white, $_ ), $_ ) } 0, 0.25, 0.5, 0.75, 1 );

# Red backgrounds with less and less alpha, blended with the light panel
# below them; alpha 0 paints nothing, so the panel shows.
my $panel = Term::Fabulous::Widget::Box->new( background_color => [ 225, 225, 210, 255 ], layout => { padding => { left => 1, right => 1 }, child_gap => 1 } );
$panel->add_child( map { swatch( [ 220, 40, 40, $_ ], "alpha $_" ) } 255, 192, 128, 64, 0 );
color_row( 'alpha', $panel );

color_row(
	'default',
	Term::Fabulous::Widget::Text->new( text => 'text_color [0, 0, 0, 0] is the terminal\'s default text color', text_color => [ 0, 0, 0, 0 ] ),
);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
