use strict;
use warnings;

use Data::HTML::Footer;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Footer;
use Tags::Output::Structure;
use Test::More 'tests' => 10;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
my $footer = Data::HTML::Footer->new;
$obj->init($footer);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'footer'],
		['e', 'footer'],
	],
	'Get Tags code (default).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
$footer = Data::HTML::Footer->new(
	'author' => 'John',
);
$obj->init($footer);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'footer'],
		['b', 'span'],
		['a', 'class', 'author'],
		['d', 'John'],
		['e', 'span'],
		['e', 'footer'],
	],
	'Get Tags code (with author only).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
$footer = Data::HTML::Footer->new(
	'author' => 'John',
	'author_url' => 'https://example.com',
);
$obj->init($footer);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'footer'],
		['b', 'span'],
		['a', 'class', 'author'],
		['b', 'a'],
		['a', 'href', 'https://example.com'],
		['d', 'John'],
		['e', 'a'],
		['e', 'span'],
		['e', 'footer'],
	],
	'Get Tags code (with author only + url).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
$footer = Data::HTML::Footer->new(
	'copyright_years' => '2022-2024',
);
$obj->init($footer);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'footer'],
		['d', decode_utf8('©').' 2022-2024'],
		['e', 'footer'],
	],
	'Get Tags code (with copyright years).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
$footer = Data::HTML::Footer->new(
	'version' => 0.07,
);
$obj->init($footer);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'footer'],
		['b', 'span'],
		['a', 'class', 'version'],
		['d', 'Version: 0.07'],
		['e', 'span'],
		['e', 'footer'],
	],
	'Get Tags code (with version only).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
$footer = Data::HTML::Footer->new(
	'version' => 0.07,
	'version_url' => '/changes',
);
$obj->init($footer);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'footer'],
		['b', 'span'],
		['a', 'class', 'version'],
		['b', 'a'],
		['a', 'href', '/changes'],
		['d', 'Version: 0.07'],
		['e', 'a'],
		['e', 'span'],
		['e', 'footer'],
	],
	'Get Tags code (with version only + url).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
$footer = Data::HTML::Footer->new(
	'author' => 'John',
	'author_url' => 'https://example.com',
	'copyright_years' => '2022-2024',
	'version' => 0.07,
	'version_url' => '/changes',
);
$obj->init($footer);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'footer'],
		['b', 'span'],
		['a', 'class', 'version'],
		['b', 'a'],
		['a', 'href', '/changes'],
		['d', 'Version: 0.07'],
		['e', 'a'],
		['e', 'span'],
		['d', ',&nbsp;'],
		['d', decode_utf8('©').' 2022-2024'],
		['d', ' '],
		['b', 'span'],
		['a', 'class', 'author'],
		['b', 'a'],
		['a', 'href', 'https://example.com'],
		['d', 'John'],
		['e', 'a'],
		['e', 'span'],
		['e', 'footer'],
	],
	'Get Tags code (with all).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Footer->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Without initialization.',
);

# Test.
$obj = Tags::HTML::Footer->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();
