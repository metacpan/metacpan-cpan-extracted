use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

my $obj = Tags::Output::Raw->new(
	'no_simple' => ['element'],
	'xml' => 1,
);
$obj->put(
	['b', 'element'],
	['e', 'element'],
);
my $ret = $obj->flush;
my $right_ret = '<element></element>';
is($ret, $right_ret, "Test for element in 'no_simple' parameter.");
