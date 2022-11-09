use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Tags::HTML::Table::View;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Table::View->new(
	'css' => $css,
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
my $ret = $obj->process_css;
is($ret, undef, 'process_css() returns undef.');
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', 'table'],
		['s', 'td'],
		['s', 'th'],
		['d', 'border', '1px solid #ddd'],
		['d', 'text-align', 'left'],
		['e'],

		['s', 'table'],
		['d', 'border-collapse', 'collapse'],
		['d', 'width', '100%'],
		['e'],

		['s', 'th'],
		['s', 'td'],
		['d', 'padding', '15px'],
		['e'],
	],
	'Get CSS structure.',
);

