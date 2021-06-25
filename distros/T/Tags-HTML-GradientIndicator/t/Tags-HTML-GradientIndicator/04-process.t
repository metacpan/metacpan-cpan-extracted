use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Tags::HTML::GradientIndicator;
use Tags::Output::Structure;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::GradientIndicator->new(
	'tags' => $tags,
);
$obj->process(0);
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'style', 'width: 0px;overflow: hidden;'],
		['b', 'div'],
		['a', 'class', 'gradient'],
		['e', 'div'],
		['e', 'div'],
	],
	'Default gradient indicator (0%).',
);

# Test.
$obj->process(30);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'style', 'width: 150px;overflow: hidden;'],
		['b', 'div'],
		['a', 'class', 'gradient'],
		['e', 'div'],
		['e', 'div'],
	],
	'Default gradient indicator (30%).',
);

# Test.
$obj->process(100);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'style', 'width: 500px;overflow: hidden;'],
		['b', 'div'],
		['a', 'class', 'gradient'],
		['e', 'div'],
		['e', 'div'],
	],
	'Default gradient indicator (100%).',
);
