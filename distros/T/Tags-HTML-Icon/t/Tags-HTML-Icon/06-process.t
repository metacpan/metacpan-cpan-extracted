use strict;
use warnings;

use Data::Icon 0.02;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Icon;
use Tags::Output::Structure;
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
my $icon = Data::Icon->new(
	'url' => 'https://example.com/image.png',
);
$obj->init($icon);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'span'],
		['a', 'class', 'icon'],
		['b', 'img'],
		['a', 'src', 'https://example.com/image.png'],
		['e', 'img'],
		['e', 'span'],
	],
	'Icon HTML code (image defined by URL).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
$icon = Data::Icon->new(
	'alt' => 'Icon image',
	'url' => 'https://example.com/image.png',
);
$obj->init($icon);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'span'],
		['a', 'class', 'icon'],
		['b', 'img'],
		['a', 'alt', 'Icon image'],
		['a', 'src', 'https://example.com/image.png'],
		['e', 'img'],
		['e', 'span'],
	],
	'Icon HTML code (image defined by URL with alternate text).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
$icon = Data::Icon->new(
	'char' => decode_utf8('†'),
);
$obj->init($icon);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'span'],
		['a', 'class', 'icon'],
		['d', decode_utf8('†')],
		['e', 'span'],
	],
	'Icon HTML code (character).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
$icon = Data::Icon->new(
	'char' => decode_utf8('†'),
	'color' => 'red',
);
$obj->init($icon);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'span'],
		['a', 'class', 'icon'],
		['b', 'span'],
		['a', 'style', 'color:red;'],
		['d', decode_utf8('†')],
		['e', 'span'],
		['e', 'span'],
	],
	'Icon HTML code (character with color).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
$icon = Data::Icon->new(
	'bg_color' => 'red',
	'char' => decode_utf8('†'),
);
$obj->init($icon);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'span'],
		['a', 'class', 'icon'],
		['b', 'span'],
		['a', 'style', 'background-color:red;'],
		['d', decode_utf8('†')],
		['e', 'span'],
		['e', 'span'],
	],
	'Icon HTML code (character with background color).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
$icon = Data::Icon->new(
	'bg_color' => 'red',
	'char' => decode_utf8('†'),
	'color' => 'grey',
);
$obj->init($icon);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'span'],
		['a', 'class', 'icon'],
		['b', 'span'],
		['a', 'style', 'background-color:red;color:grey;'],
		['d', decode_utf8('†')],
		['e', 'span'],
		['e', 'span'],
	],
	'Icon HTML code (character with foreground and background colors).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Icon HTML code (no init).',
);

# Test.
$obj = Tags::HTML::Icon->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();
