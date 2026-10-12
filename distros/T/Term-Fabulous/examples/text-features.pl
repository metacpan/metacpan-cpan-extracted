#!/usr/bin/env perl

# Term::Fabulous::Widget::Text: the two wrap modes, line height, bold,
# italic and underlined text, wide characters, emoji and combining marks
# lined up in columns, and control characters made harmless. Ctrl+C
# quits.
#
#     perl examples/text-features.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM CLAY_TEXT_WRAP_NEWLINES);

my $label_color = [ 150, 160, 180, 255 ];
my $text_color  = [ 230, 230, 230, 255 ];
my $panel_color = [ 35,  42,  60,  255 ];

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A row with a label in a column of its own and the given widgets.
sub feature_row ( $label, @widgets ) {
	my $label_box = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$label_box->add_child( Term::Fabulous::Widget::Text->new( text => $label, text_color => $label_color ) );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child( $label_box, @widgets );
	$root->add_child($row);
	return;
}

# A Text on a panel, so that the room the Text takes is visible.
sub panel ( $text, %options ) {
	my $width = delete $options{width};
	my $box   = Term::Fabulous::Widget::Box->new(
		background_color => $panel_color,
		defined $width ? ( layout => { sizing => { width => sizing_fixed($width) } } ) : (),
	);
	$box->add_child( Term::Fabulous::Widget::Text->new( text => $text, text_color => $text_color, %options ) );
	return $box;
}

feature_row(
	'wrap_mode',
	panel( "words: breaks at spaces where a line does not fit,\nand at newlines.",    width     => 24 ),
	panel( "newlines: breaks only\nat newlines; the box\ngrows to the longest line.", wrap_mode => CLAY_TEXT_WRAP_NEWLINES ),
);

feature_row( 'line_height 2', panel( "First line\nSecond line", line_height => 2 ) );

feature_row(
	'styles',
	map { Term::Fabulous::Widget::Text->new( text => $_->[0], text_color => $text_color, $_->[1]->%* ) } [ 'plain', {} ], [ 'bold', { bold => 1 } ], [ 'italic', { italic => 1 } ],
	[ 'underline', { underline => 1 } ],
	[ 'all three', { bold      => 1, italic => 1, underline => 1 } ],
);

feature_row( 'wide and emoji', panel("abcdef|\n日本語|\n🙂🎉ok|\ne\x{301}e\x{301}e\x{301}xyz|") );

feature_row( 'control chars', panel("tab:\tend, bell:\a, escape:\e[31m") );

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
