use strict;
use warnings;

use Tags::Output::Structure;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Structure->new;
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[],
	'Get output from flush().',
);

# Test.
$obj = Tags::Output::Structure->new;
$obj->put(
	['c', 'comment'],
);
$ret_ar = $obj->flush;
is_deeply($ret_ar, [
	['c', 'comment'],
], 'First get of flush without reset.');
$ret_ar = $obj->flush;
is_deeply($ret_ar, [
	['c', 'comment'],
], 'Second get of flush without reset.');

# Test.
$obj = Tags::Output::Structure->new;
$obj->put(
	['c', 'comment'],
);
$ret_ar = $obj->flush(1);
is_deeply($ret_ar, [
	['c', 'comment'],
], 'First get of flush with reset.');
$ret_ar = $obj->flush;
is_deeply($ret_ar, [], 'Second get of flush with reset.');
