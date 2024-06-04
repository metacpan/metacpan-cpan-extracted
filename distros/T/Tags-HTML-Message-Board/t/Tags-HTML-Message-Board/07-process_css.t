use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Tags::HTML::Message::Board;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::Message::Board::Example;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Message::Board->new(
	'css' => $css,
);
my $board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);
my $ret = $obj->process_css;
is($ret, undef, 'Process CSS returns undef.');
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		# Main CSS.
		['s', '.message-board .main-message'],
		['d', 'border', '1px solid #ccc'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'background-color', '#f9f9f9'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.message-board .comments'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.message-board .comment'],
		['d', 'border-left', '2px solid #ccc'],
		['d', 'padding-left', '10px'],
		['d', 'margin-top', '20px'],
		['d', 'margin-left', '10px'],
		['e'],

		['s', '.author'],
		['d', 'font-weight', 'bold'],
		['d', 'font-size', '1.2em'],
		['e'],

		['s', '.comment .author'],
		['d', 'font-size', '1em'],
		['e'],

		['s', '.date'],
		['d', 'color', '#555'],
		['d', 'font-size', '0.9em'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.comment .date'],
		['d', 'font-size', '0.8em'],
		['e'],

		['s', '.text'],
		['d', 'margin-top', '10px'],
		['e'],

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

		# Comments.
		['s', '.message-board .add-comment'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.message-board .add-comment .title'],
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
$obj = Tags::HTML::Message::Board->new(
	'css' => $css,
	'mode_comment_form' => 0,
);
$board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		# Main CSS.
		['s', '.message-board .main-message'],
		['d', 'border', '1px solid #ccc'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'background-color', '#f9f9f9'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.message-board .comments'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.message-board .comment'],
		['d', 'border-left', '2px solid #ccc'],
		['d', 'padding-left', '10px'],
		['d', 'margin-top', '20px'],
		['d', 'margin-left', '10px'],
		['e'],

		['s', '.author'],
		['d', 'font-weight', 'bold'],
		['d', 'font-size', '1.2em'],
		['e'],

		['s', '.comment .author'],
		['d', 'font-size', '1em'],
		['e'],

		['s', '.date'],
		['d', 'color', '#555'],
		['d', 'font-size', '0.9em'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.comment .date'],
		['d', 'font-size', '0.8em'],
		['e'],

		['s', '.text'],
		['d', 'margin-top', '10px'],
		['e'],
	],
	'Message board CSS code (without add comment form).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Message::Board->new(
	'css' => $css,
	'css_class' => 'my-board',
);
$board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		# Main CSS.
		['s', '.my-board .main-message'],
		['d', 'border', '1px solid #ccc'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '5px'],
		['d', 'background-color', '#f9f9f9'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.my-board .comments'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.my-board .comment'],
		['d', 'border-left', '2px solid #ccc'],
		['d', 'padding-left', '10px'],
		['d', 'margin-top', '20px'],
		['d', 'margin-left', '10px'],
		['e'],

		['s', '.author'],
		['d', 'font-weight', 'bold'],
		['d', 'font-size', '1.2em'],
		['e'],

		['s', '.comment .author'],
		['d', 'font-size', '1em'],
		['e'],

		['s', '.date'],
		['d', 'color', '#555'],
		['d', 'font-size', '0.9em'],
		['d', 'margin-bottom', '10px'],
		['e'],

		['s', '.comment .date'],
		['d', 'font-size', '0.8em'],
		['e'],

		['s', '.text'],
		['d', 'margin-top', '10px'],
		['e'],

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

		# Comments.
		['s', '.my-board .add-comment'],
		['d', 'max-width', '600px'],
		['d', 'margin', 'auto'],
		['e'],

		['s', '.my-board .add-comment .title'],
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
