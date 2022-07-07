use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tags::Output::Structure;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Structure->new;
$obj->put(
	['b', 'MAIN'],
	['d', 'data'],
	['e', 'MAIN'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['b', 'MAIN'],
		['d', 'data'],
		['e', 'MAIN'],
	],
	'Element.',
);

# Test.
$obj = Tags::Output::Structure->new;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['d', 'data'],
	['e', 'MAIN'],
);
$ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['b', 'MAIN'],
		['a', 'id', 'id_value'],
		['d', 'data'],
		['e', 'MAIN'],
	],
	'Element with attribute.',
);

# Test.
$obj = Tags::Output::Structure->new;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['d', 'data'],
	['e', 'MAIN'],
	['b', 'MAIN'],
	['a', 'id', 'id_value2'],
	['d', 'data'],
	['e', 'MAIN'],
);
$ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['b', 'MAIN'],
		['a', 'id', 'id_value'],
		['d', 'data'],
		['e', 'MAIN'],
		['b', 'MAIN'],
		['a', 'id', 'id_value2'],
		['d', 'data'],
		['e', 'MAIN'],
	],
	'Two elements with attribute.',
);

# Test.
my $long_data = 'a' x 1000;
$obj = Tags::Output::Structure->new;
$obj->put(
	['b', 'MAIN'],
	['d', $long_data],
	['e', 'MAIN'],
);
$ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['b', 'MAIN'],
		['d', $long_data],
		['e', 'MAIN'],
	],
	'Long data in element.',
);

# Test.
$long_data = 'aaaa ' x 1000;
$obj = Tags::Output::Structure->new;
$obj->put(
	['b', 'MAIN'],
	['d', $long_data],
	['e', 'MAIN'],
);
$ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['b', 'MAIN'],
		['d', $long_data],
		['e', 'MAIN'],
	],
	'Another long data in element.',
);

# Test.
$obj = Tags::Output::Structure->new;
eval {
	$obj->put(
		['b', 'MAIN'],
		['e', 'MAIN2'],
	);
};
is($EVAL_ERROR, "Ending bad tag: 'MAIN2' in block of tag 'MAIN'.\n",
	"Ending bad tag: 'MAIN2' in block of tag 'MAIN'.");
clean();
