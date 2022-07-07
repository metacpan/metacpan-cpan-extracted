use strict;
use warnings;

use Tags::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Structure->new;
$obj->put(
	['r', '<?xml version="1.1"?>'."\n"],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['r', '<?xml version="1.1"?>'."\n"],
	],
	'Simple raw data test.',
);
