use strict;
use warnings;

use Data::HTML::Element::A;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::A;
use Tags::Output::Structure;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Element::A->new(
	'tags' => $tags,
);
my $anchor = Data::HTML::Element::A->new;
$obj->init($anchor);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'a'],
		['e', 'a'],
	],
	'Get Tags code (default).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::A->new(
	'tags' => $tags,
);
$anchor = Data::HTML::Element::A->new(
	'css_class' => 'foo',
	'data' => ['Link'],
	'id' => 'one',
	'target' => '_blank',
);
$obj->init($anchor);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'a'],
		['a', 'class', 'foo'],
		['a', 'id', 'one'],
		['a', 'target', '_blank'],
		['d', 'Link'],
		['e', 'a'],
	],
	'Get Tags code (with CSS class, id, target and data).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::A->new(
	'tags' => $tags,
);
$anchor = Data::HTML::Element::A->new(
	'data' => ['Link'],
	'url' => 'https://example.com',
);
$obj->init($anchor);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'a'],
		['a', 'href', 'https://example.com'],
		['d', 'Link'],
		['e', 'a'],
	],
	'Get Tags code (with href and data).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::A->new(
	'tags' => $tags,
);
$anchor = Data::HTML::Element::A->new(
	'data' => [['b', 'span'], ['d', 'Link'], ['e', 'span']],
	'data_type' => 'tags',
	'url' => 'https://example.com',
);
$obj->init($anchor);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'a'],
		['a', 'href', 'https://example.com'],
		['b', 'span'],
		['d', 'Link'],
		['e', 'span'],
		['e', 'a'],
	],
	'Get Tags code (with href and Tags data).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::A->new(
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
$obj = Tags::HTML::Element::A->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();
