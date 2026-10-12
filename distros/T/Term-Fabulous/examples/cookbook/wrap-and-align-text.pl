#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous::Static;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(
	sizing_fixed CLAY_TOP_TO_BOTTOM CLAY_ALIGN_X_CENTER
	CLAY_TEXT_ALIGN_CENTER CLAY_TEXT_ALIGN_RIGHT CLAY_TEXT_WRAP_NEWLINES
);

my $words = "Text wraps at spaces to the width of its box.\nA line break starts a new line.";

# A framed box, 24 columns wide, with a caption and a Text that gets the
# given options. 'box_layout' replaces the layout of the box.
sub sample ( $caption, $text, %options ) {
	my $box_layout = delete $options{box_layout} // { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(24) } };
	my $box        = Term::Fabulous::Widget::Box->new(
		bordered     => 1,
		border_style => Term::Fabulous::Enum::BorderStyle->Ascii,
		border_color => [ 120, 160, 220, 255 ],
		layout       => $box_layout,
	);
	$box->add_child(
		Term::Fabulous::Widget::Text->new( text => $caption, text_color => [ 255, 200, 80,  255 ] ),
		Term::Fabulous::Widget::Text->new( text => $text,    text_color => [ 230, 230, 230, 255 ], %options ),
	);
	return $box;
}

# Three samples side by side in each row.
sub row (@samples) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child(@samples);
	return $row;
}

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 1 } );
$root->add_child(
	row(
		sample( 'Default: wrap at words', $words ),
		sample( 'Centered lines',         $words, text_alignment => CLAY_TEXT_ALIGN_CENTER ),
		sample( 'Right-aligned lines',    $words, text_alignment => CLAY_TEXT_ALIGN_RIGHT ),
	),
	row(
		sample( 'Line breaks only',  "No wrapping at spaces,\nonly at line breaks.", wrap_mode   => CLAY_TEXT_WRAP_NEWLINES ),
		sample( 'Two rows per line', "First line\nSecond line",                      line_height => 2 ),
		sample(
			'A centered label', 'OK',
			box_layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(24) }, child_alignment => { x => CLAY_ALIGN_X_CENTER } },
		),
	),
);

# Colors only when STDOUT is a terminal.
Term::Fabulous::Static->new( root => $root, width => 76 )->print;
