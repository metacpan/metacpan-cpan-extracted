use strict;
use warnings;

use Tags::HTML::Login::Button;
use Tags::Output::Structure;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Login::Button->new(
	'tags' => $tags,
);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['a', 'class', 'outer'],

		['b', 'div'],
		['a', 'class', 'login'],
		['b', 'a'],
		['a', 'href', 'login'],
		['d', 'LOGIN'],
		['e', 'a'],
		['e', 'div'],
	],
	'Default login button.',
);

# Test.
$obj = Tags::HTML::Login::Button->new(
	'link' => 'https://example.com/login',
	'tags' => $tags,
	'title' => 'Button login',
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['a', 'class', 'outer'],

		['b', 'div'],
		['a', 'class', 'login'],
		['b', 'a'],
		['a', 'href', 'https://example.com/login'],
		['d', 'Button login'],
		['e', 'a'],
		['e', 'div'],
	],
	'Login button with explicit link a title.',
);
