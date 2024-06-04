use strict;
use warnings;

use Tags::HTML::Message::Board;
use Tags::Output::Structure;
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::Message::Board::Example;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Message::Board->new(
	'tags' => $tags,
);
my $board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);
my $ret = $obj->process;
is($ret, undef, 'Process returns undef.');
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'message-board'],

		['b', 'div'],
		['a', 'class', 'main-message'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: John Wick'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:20'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'How to install Perl?'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comments'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: Gregor Herrmann'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:27'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'apt-get update; apt-get install perl;'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: Emmanuel Seyman'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:37'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'dnf update; dnf install perl-intepreter;'],
		['e', 'div'],
		['e', 'div'],

		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'add-comment'],
		['b', 'div'],
		['a', 'class', 'title'],
		['d', 'Add comment'],
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

		['e', 'div'],
	],
	'Message board HTML code (default).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Message::Board->new(
	'mode_comment_form' => 0,
	'tags' => $tags,
);
$board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'message-board'],

		['b', 'div'],
		['a', 'class', 'main-message'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: John Wick'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:20'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'How to install Perl?'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comments'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: Gregor Herrmann'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:27'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'apt-get update; apt-get install perl;'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: Emmanuel Seyman'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:37'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'dnf update; dnf install perl-intepreter;'],
		['e', 'div'],
		['e', 'div'],

		['e', 'div'],

		['e', 'div'],
	],
	'Message board HTML code (without add comment form).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Message::Board->new(
	'css_class' => 'my-board',
	'tags' => $tags,
);
$board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'my-board'],

		['b', 'div'],
		['a', 'class', 'main-message'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: John Wick'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:20'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'How to install Perl?'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comments'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: Gregor Herrmann'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:27'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'apt-get update; apt-get install perl;'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Author: Emmanuel Seyman'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Date: 25.05.2024 17:53:37'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'dnf update; dnf install perl-intepreter;'],
		['e', 'div'],
		['e', 'div'],

		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'add-comment'],
		['b', 'div'],
		['a', 'class', 'title'],
		['d', 'Add comment'],
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

		['e', 'div'],
	],
	'Message board HTML code (different CSS class).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Message::Board->new(
	'lang' => 'cze',
	'text' => {
		'cze' => {
			'add_comment' => decode_utf8('Přidat komentář'),
			'author' => 'Autor',
			'date' => 'Datum',
			'save' => decode_utf8('Uložit'),
		},
	},
	'tags' => $tags,
);
$board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'message-board'],

		['b', 'div'],
		['a', 'class', 'main-message'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Autor: John Wick'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Datum: 25.05.2024 17:53:20'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'How to install Perl?'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comments'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Autor: Gregor Herrmann'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Datum: 25.05.2024 17:53:27'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'apt-get update; apt-get install perl;'],
		['e', 'div'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'comment'],
		['b', 'div'],
		['a', 'class', 'author'],
		['d', 'Autor: Emmanuel Seyman'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'date'],
		['d', 'Datum: 25.05.2024 17:53:37'],
		['e', 'div'],
		['b', 'div'],
		['a', 'class', 'text'],
		['d', 'dnf update; dnf install perl-intepreter;'],
		['e', 'div'],
		['e', 'div'],

		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'add-comment'],
		['b', 'div'],
		['a', 'class', 'title'],
		['d', decode_utf8('Přidat komentář')],
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

		['e', 'div'],
	],
	'Message board HTML code (texts in Czech language).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Message::Board->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Message board HTML code (no init).',
);
