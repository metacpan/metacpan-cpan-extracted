use strict;
use warnings;

use Tags::Output::Structure;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Structure->new;
$obj->put(
	['b', 'MAIN'],
	['e', 'MAIN'],
);
my $ret = $obj->flush;
is_deeply(
	$ret,
	[
		['b', 'MAIN'],
		['e', 'MAIN'],
	],
	'Simple element in uppercase form.',
);

# Test.
$obj->reset;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
is_deeply(
	$ret,
	[
		['b', 'MAIN'],
		['a', 'id', 'id_value'],
		['e', 'MAIN'],
	],
	'Simple element with attribute in uppercase form.',
);

# Test.
$obj->reset;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
	['b', 'MAIN'],
	['a', 'id', 'id_value2'],
	['e', 'MAIN']
);
$ret = $obj->flush;
is_deeply(
	$ret,
	[
		['b', 'MAIN'],
		['a', 'id', 'id_value'],
		['e', 'MAIN'],
		['b', 'MAIN'],
		['a', 'id', 'id_value2'],
		['e', 'MAIN']
	],
	'Two elements with attributes in uppercase form.',
);

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['e', 'main'],
);
$ret = $obj->flush;
is_deeply(
	$ret,
	[
		['b', 'main'],
		['e', 'main'],
	],
	'Simple element in lowercase form.',
);

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
);
$ret = $obj->flush;
is_deeply(
	$ret,
	[
		['b', 'main'],
		['a', 'id', 'id_value'],
		['e', 'main'],
	],
	'Simple element with attribute in lowercase form.',
);

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
	['b', 'main'],
	['a', 'id', 'id_value2'],
	['e', 'main'],
);
$ret = $obj->flush;
is_deeply(
	$ret,
	[
		['b', 'main'],
		['a', 'id', 'id_value'],
		['e', 'main'],
		['b', 'main'],
		['a', 'id', 'id_value2'],
		['e', 'main'],
	],
	'Two elements with attributes in lowercase form.',
);
