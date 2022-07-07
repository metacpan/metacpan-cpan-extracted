use strict;
use warnings;

use Tags::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Structure->new;
$obj->put(
	['i', 'perl'],
	['i', 'perl', 'print "1";'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['i', 'perl'],
		['i', 'perl', 'print "1";'],
	],
	'Simple instruction test.',
);
