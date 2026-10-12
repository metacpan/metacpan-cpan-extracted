use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_fixed);
use InputTest;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Layout;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Divider;

# A divider in a box of the given width.
sub sized ( $columns, %args ) {
	return Term::Fabulous::Widget::Divider->new( %args, layout => { sizing => { width => sizing_fixed($columns) } } );
}

subtest 'horizontal lines and texts' => sub {
	my @dividers = (
		sized(20),
		sized( 20, text => 'Mid' ),
		sized( 20, text => 'Start', text_position => 'start' ),
		sized( 20, text => 'End',   text_position => 'end', text_margin => 3 ),
		sized( 20, text => 'Pad',   text_padding  => 0,     line_style  => Term::Fabulous::Enum::BorderStyle->Double ),
		sized( 20, text => 'far too long for the line' ),
	);
	my $ui = layout_ui(@dividers);
	is [ map { [ $_->columns, $_->rows ] } @dividers ], [ ( [ 20, 1 ] ) x 6 ], 'one row high, the width of the layout';
	is row_text( $dividers[0], 0 ),                                                    "\x{2500}" x 20, 'a plain line';
	is row_text( $dividers[1], 0 ), ( "\x{2500}" x 7 ) . ' Mid ' . ( "\x{2500}" x 8 ), 'a text in the middle, with a space on each side';
	is row_text( $dividers[2], 0 ),                                                     "\x{2500} Start " . ( "\x{2500}" x 12 ), 'a text at the start, after the margin';
	is row_text( $dividers[3], 0 ), ( "\x{2500}" x 12 ) . ' End ' . ( "\x{2500}" x 3 ), 'a text at the end, before the margin';
	is row_text( $dividers[4], 0 ), ( "\x{2550}" x 8 ) . 'Pad' . ( "\x{2550}" x 9 ),    'no padding, the Double style';
	is row_text( $dividers[5], 0 ),                                                     "\x{2500}" x 20, 'a text that does not fit is left out';

	$dividers[0]->glyph('=');
	is row_text( $dividers[0], 0 ), '=' x 20, 'a glyph of your own wins over the style';
	$dividers[0]->glyph(undef);
	$dividers[0]->line_style('Heavy');
	is [ row_text( $dividers[0], 0 ), $dividers[0]->line_style->name ], [ "\x{2501}" x 20, 'Heavy' ], 'a style by name';
};

subtest 'vertical lines write the text downwards' => sub {
	my $row   = Term::Fabulous::Widget::Box->new( layout => { sizing => { height => sizing_fixed(7) }, child_gap => 1 } );
	my $plain = Term::Fabulous::Widget::Divider->new( vertical => 1 );
	my $text  = Term::Fabulous::Widget::Divider->new( vertical => 1, text => 'ab', text_position => 'start', text_padding => 0 );
	my $wide  = Term::Fabulous::Widget::Divider->new( vertical => 1, text => "\x{65E5}\x{672C}", text_position => 'end' );
	$row->add_child( $plain, $text, $wide );
	my $ui = layout_ui($row);
	is [ map { [ $_->columns, $_->rows ] } $plain, $text, $wide ], [ [ 1, 7 ], [ 1, 7 ], [ 2, 7 ] ],           'one column wide, two for wide characters, the height of the layout';
	is [ map { row_text( $plain, $_ ) } 0 .. 6 ],                  [ ("\x{2502}") x 7 ],                       'a plain vertical line';
	is [ map { row_text( $text, $_ ) } 0 .. 6 ],                   [ "\x{2502}", 'a', 'b', ("\x{2502}") x 4 ], 'the text after the margin, one character per row';
	is [ map { row_text( $wide, $_ ) } 0 .. 6 ],                   [ ("\x{2502} ") x 2, '  ', "\x{65E5}", "\x{672C}", '  ', "\x{2502} " ], 'wide characters, padded, before the margin at the end';
};

subtest 'a KDL layout sets every property' => sub {
	my $divider = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Divider as Divider
Divider "d" {
	text "Settings"
	text_position "start"
	text_margin 2
	text_padding 0
	line_style "Dashed"
	color "#61afef"
	text_color "#ffffff"
	bold #true
	vertical #false
}
KDL
	is [
		$divider->text, $divider->text_position, $divider->text_margin, $divider->text_padding, $divider->line_style->name, $divider->color, $divider->text_color, $divider->bold,
		$divider->vertical
		],
		[ 'Settings', 'start', 2, 0, 'Dashed', [ 97, 175, 239, 255 ], [ 255, 255, 255, 255 ], 1, 0 ], 'the properties of the layout';
};

subtest 'invalid values die' => sub {
	like dies { Term::Fabulous::Widget::Divider->new( text_position => 'middle' ) }, qr/text_position must be one of center, end, start/,                             'an unknown position';
	like dies { Term::Fabulous::Widget::Divider->new( line_style    => 'Fancy' ) },  qr/line_style must be a border style or its name, got 'Fancy' \(known: Ascii, /, 'an unknown style';
	like dies { Term::Fabulous::Widget::Divider->new( glyph         => 'ab' ) },     qr/glyph must be a single character/,                                            'a glyph of two characters';
	like dies { Term::Fabulous::Widget::Divider->new( text_margin   => -1 ) },       qr/text_margin must be a non-negative integer/,                                  'a negative margin';
	my $divider = Term::Fabulous::Widget::Divider->new( text => 'ok' );
	like dies { $divider->text( [] ) }, qr/text must be a string/, 'the accessor checks too';
	is $divider->text, 'ok', 'and leaves the value';
};

done_testing;
