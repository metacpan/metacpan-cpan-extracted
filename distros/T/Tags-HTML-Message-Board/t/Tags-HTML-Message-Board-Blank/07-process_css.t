use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Tags::HTML::Message::Board::Blank;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Message::Board::Blank->new(
	'css' => $css,
);
my $ret = $obj->process_css;
is($ret, undef, 'Process CSS returns undef.');
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		# Textarea.
		['s', 'textarea'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],

		# Button.
		['s', 'button'],	
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],
		['s', 'button:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		# Main CSS.
		['s', '.message-board-blank'],
		['d', 'margin', '1em'],
		['e'],

		['s', '.message-board-blank .new-message-board'],
		['d', 'font-family', 'Arial, Helvetica, sans-serif'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.message-board-blank .title'],
		['d', 'margin-top', '20px'],
		['d', 'font-weight', 'bold'],
		['d', 'font-size', '1.2em'],
		['e'],

		['s', 'button'],
		['d', 'margin', 0],
		['e'],
	],
	'Message board CSS code (default).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Message::Board::Blank->new(
	'css' => $css,
	'css_class' => 'my-blank',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		# Textarea.
		['s', 'textarea'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],

		# Button.
		['s', 'button'],	
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],
		['s', 'button:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		# Main CSS.
		['s', '.my-blank'],
		['d', 'margin', '1em'],
		['e'],

		['s', '.my-blank .new-message-board'],
		['d', 'font-family', 'Arial, Helvetica, sans-serif'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.my-blank .title'],
		['d', 'margin-top', '20px'],
		['d', 'font-weight', 'bold'],
		['d', 'font-size', '1.2em'],
		['e'],

		['s', 'button'],
		['d', 'margin', 0],
		['e'],
	],
	'Message board CSS code (different CSS class).',
);
