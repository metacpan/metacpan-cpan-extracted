use strict;
use warnings;

use Tags::HTML::Table::View;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Table::View->new;
my $ret = $obj->init([
	[
		'Title col #1',
		'Title col #2',
	],
	[
		'Data col #1',
		'Data col #2',
	],
], 'No data.');
is($ret, undef, 'Init returns undef.');
