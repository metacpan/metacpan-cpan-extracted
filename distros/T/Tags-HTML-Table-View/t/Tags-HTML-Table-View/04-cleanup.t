use strict;
use warnings;

use Tags::HTML::Table::View;
use Tags::Output::Structure;
use Test::More 'tests' => 3;
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
$obj->process;
$tags->reset(1);
my $ret = $obj->cleanup;
is($ret, undef, 'cleanup() returns undef.');
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	# XXX Bad output.
	[
		['b', 'table'],
		['a', 'class', 'table'],
		['b', 'tr'],
		['e', 'tr'],
		['e', 'table'],
	],
	'Process again and test that data was cleaned.',
);
