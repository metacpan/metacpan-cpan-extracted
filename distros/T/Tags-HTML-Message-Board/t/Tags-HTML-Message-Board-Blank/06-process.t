use strict;
use warnings;

use Tags::HTML::Message::Board::Blank;
use Tags::Output::Structure;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Message::Board::Blank->new(
	'tags' => $tags,
);
my $ret = $obj->process;
is($ret, undef, 'Process returns undef.');
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'message-board-blank'],

		['b', 'div'],
		['a', 'class', 'title'],
		['d', 'Add message board'],
		['e', 'div'],
		['b', 'form'],
		['a', 'method', 'post'],
		['b', 'textarea'],
		['a', 'autofocus', 'autofocus'],
		['a', 'rows', '6'],
		['e', 'textarea'],
		['b', 'button'],
		['a', 'type', 'button'],
		['d', 'Save'],
		['e', 'button'],
		['e', 'form'],

		['e', 'div'],
	],
	'Blank message board HTML code (default).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Message::Board::Blank->new(
	'css_class' => 'my-blank',
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'my-blank'],

		['b', 'div'],
		['a', 'class', 'title'],
		['d', 'Add message board'],
		['e', 'div'],
		['b', 'form'],
		['a', 'method', 'post'],
		['b', 'textarea'],
		['a', 'autofocus', 'autofocus'],
		['a', 'rows', '6'],
		['e', 'textarea'],
		['b', 'button'],
		['a', 'type', 'button'],
		['d', 'Save'],
		['e', 'button'],
		['e', 'form'],

		['e', 'div'],
	],
	'Blank message board HTML code (different CSS class).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Message::Board::Blank->new(
	'lang' => 'cze',
	'text' => {
		'cze' => {
			'add_message_board' => decode_utf8('Vytvořit nástěnku'),
			'save' => decode_utf8('Uložit'),
		},
	},
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'message-board-blank'],

		['b', 'div'],
		['a', 'class', 'title'],
		['d', decode_utf8('Vytvořit nástěnku')],
		['e', 'div'],
		['b', 'form'],
		['a', 'method', 'post'],
		['b', 'textarea'],
		['a', 'autofocus', 'autofocus'],
		['a', 'rows', '6'],
		['e', 'textarea'],
		['b', 'button'],
		['a', 'type', 'button'],
		['d', decode_utf8('Uložit')],
		['e', 'button'],
		['e', 'form'],

		['e', 'div'],
	],
	'Message board HTML code (texts in Czech language).',
);
