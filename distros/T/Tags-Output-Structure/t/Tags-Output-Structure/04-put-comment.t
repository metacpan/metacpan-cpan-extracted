use strict;
use warnings;

use Tags::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Structure->new;
$obj->put(
	['c', 'comment'],
	['c', ' comment '],
);
my $ret = $obj->flush;
is_deeply(
	$ret,
	[
		['c', 'comment'],
		['c', ' comment '],
	],
	'Simple comment test.',
);
