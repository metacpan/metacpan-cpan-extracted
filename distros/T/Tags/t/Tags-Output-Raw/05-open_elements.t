use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new;
my @ret = $obj->open_elements;
is_deeply(\@ret, [], 'List of open elements in begin.');

$obj->put(
	['b', 'element'],
);
@ret = $obj->open_elements;
is_deeply(\@ret, ['element'], 'List of open elements after adding element.');

# Test.
$obj->put(
	['b', 'other_element'],
);
@ret = $obj->open_elements;
is_deeply(\@ret, ['other_element', 'element'],
	'List of open elements after adding other element.');

# Test.
$obj->finalize;
@ret = $obj->open_elements;
is_deeply(\@ret, [], 'List of open elements after finalization.');
