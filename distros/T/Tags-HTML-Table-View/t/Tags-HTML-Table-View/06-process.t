use strict;
use warnings;

use Tags::HTML::Table::View;
use Tags::Output::Structure;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Table::View->new(
	'tags' => $tags,
);
$obj->init([
	[
		'Title col #1',
		'Title col #2',
	],
	[
		'Data col #1',
		'Data col #2',
	],
], 'No data.');
my $ret = $obj->process;
is($ret, undef, 'process() returns undef.');
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'table'],
		['a', 'class', 'table'],
		['b', 'tr'],
		['b', 'th'],
		['d', 'Title col #1'],
		['e', 'th'],
		['b', 'th'],
		['d', 'Title col #2'],
		['e', 'th'],
		['e', 'tr'],
		['b', 'tr'],
		['b', 'td'],
		['d', 'Data col #1'],
		['e', 'td'],
		['b', 'td'],
		['d', 'Data col #2'],
		['e', 'td'],
		['e', 'tr'],
		['e', 'table'],
	],
	'Tags code for table with data.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Table::View->new(
	'tags' => $tags,
);
$obj->init([
	[
		'Title col #1',
		'Title col #2',
	],
], 'No data.');
$ret = $obj->process;
is($ret, undef, 'process() returns undef.');
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'table'],
		['a', 'class', 'table'],
		['b', 'tr'],
		['b', 'th'],
		['d', 'Title col #1'],
		['e', 'th'],
		['b', 'th'],
		['d', 'Title col #2'],
		['e', 'th'],
		['e', 'tr'],
		['b', 'tr'],
		['b', 'td'],
		['a', 'colspan', 2],
		['d', 'No data.'],
		['e', 'td'],
		['e', 'tr'],
		['e', 'table'],
	],
	'Tags code for table without data.',
);
