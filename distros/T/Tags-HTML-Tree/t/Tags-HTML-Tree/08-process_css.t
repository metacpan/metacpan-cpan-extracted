use strict;
use warnings;

use Tags::HTML::Tree;
use CSS::Struct::Output::Structure;
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Tree;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Tree->new(
	'css' => $css,
);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'ul, .tree'],
		['d', 'list-style-type', 'none'],
		['d', 'padding-left', '2em'],
		['e'],

		['s', '.caret'],
		['d', 'cursor', 'pointer'],
		['d', '-webkit-user-select', 'none'],
		['d', '-moz-user-select', 'none'],
		['d', '-ms-user-select', 'none'],
		['d', 'user-select', 'none'],
		['e'],

		['s', '.caret::before'],
		['d', 'content', decode_utf8('"⯈"')],
		['d', 'color', 'black'],
		['d', 'display', 'inline-block'],
		['d', 'margin-right', '6px'],
		['e'],

		['s', '.caret-down::before'],
		['d', 'transform', 'rotate(90deg)'],
		['e'],

		['s', '.nested'],
		['d', 'display', 'none'],
		['e'],

		['s', '.active'],
		['d', 'display', 'block'],
		['e'],
	],
	'CSS::Struct code for Tree.',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Tree->new(
	'css' => $css,
	'css_class' => 'foo',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'ul, .foo'],
		['d', 'list-style-type', 'none'],
		['d', 'padding-left', '2em'],
		['e'],

		['s', '.caret'],
		['d', 'cursor', 'pointer'],
		['d', '-webkit-user-select', 'none'],
		['d', '-moz-user-select', 'none'],
		['d', '-ms-user-select', 'none'],
		['d', 'user-select', 'none'],
		['e'],

		['s', '.caret::before'],
		['d', 'content', decode_utf8('"⯈"')],
		['d', 'color', 'black'],
		['d', 'display', 'inline-block'],
		['d', 'margin-right', '6px'],
		['e'],

		['s', '.caret-down::before'],
		['d', 'transform', 'rotate(90deg)'],
		['e'],

		['s', '.nested'],
		['d', 'display', 'none'],
		['e'],

		['s', '.active'],
		['d', 'display', 'block'],
		['e'],
	],
	'CSS::Struct code for Tree (explicit css_class).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Tree->new(
	'css' => $css,
	'indent' => '3px',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'ul, .tree'],
		['d', 'list-style-type', 'none'],
		['d', 'padding-left', '3px'],
		['e'],

		['s', '.caret'],
		['d', 'cursor', 'pointer'],
		['d', '-webkit-user-select', 'none'],
		['d', '-moz-user-select', 'none'],
		['d', '-ms-user-select', 'none'],
		['d', 'user-select', 'none'],
		['e'],

		['s', '.caret::before'],
		['d', 'content', decode_utf8('"⯈"')],
		['d', 'color', 'black'],
		['d', 'display', 'inline-block'],
		['d', 'margin-right', '6px'],
		['e'],

		['s', '.caret-down::before'],
		['d', 'transform', 'rotate(90deg)'],
		['e'],

		['s', '.nested'],
		['d', 'display', 'none'],
		['e'],

		['s', '.active'],
		['d', 'display', 'block'],
		['e'],
	],
	'CSS::Struct code for Tree (explicit indent).',
);
