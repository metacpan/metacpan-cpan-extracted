#!/usr/bin/env perl

# Term::Fabulous::Widget::Divider: a plain line, lines with a text at the
# start, in the center and at the end, lines in other styles and colors,
# and a vertical divider with a text between two columns. Ctrl+C quits.
#
#     perl examples/widgets/divider.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Divider;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

sub text ( $string, $color = [ 220, 223, 228, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

$root->add_child(
	Term::Fabulous::Widget::Divider->new,
	Term::Fabulous::Widget::Divider->new( text => 'Settings' ),
	Term::Fabulous::Widget::Divider->new( text => 'Files',       text_position => 'start',                                   bold        => 1, text_color => [ 255, 255, 255, 255 ] ),
	Term::Fabulous::Widget::Divider->new( text => 'end of list', text_position => 'end',                                     text_margin => 2 ),
	Term::Fabulous::Widget::Divider->new( text => 'Double',      line_style    => Term::Fabulous::Enum::BorderStyle->Double, color       => [ 97, 175, 239, 255 ] ),
	Term::Fabulous::Widget::Divider->new( text => 'Heavy',       line_style    => 'Heavy',                                   color => [ 152, 195, 121, 255 ], text_color => [ 152, 195, 121, 255 ] ),
	Term::Fabulous::Widget::Divider->new( text => 'glyph',       glyph         => '~',                                       color => [ 229, 192, 123, 255 ] ),
);

# Two columns with a vertical divider between them, its text written
# downwards.
my $columns = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 } );
my $left    = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $right   = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$left->add_child( map { text($_) } 'Inbox', 'Drafts', 'Sent' );
$right->add_child( map { text($_) } 'From: Ada', 'Subject: Notes on the engine', '' );
$columns->add_child( $left, Term::Fabulous::Widget::Divider->new( vertical => 1, text => 'mail' ), $right );
$root->add_child($columns);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->run;
