use strict;
use warnings;

use Tags::Output::PYX;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::PYX->new;
my @ret = $obj->open_elements;
is_deeply(\@ret, []);

# Test.
$obj->put(
	['b', 'element'],
);
@ret = $obj->open_elements;
is_deeply(\@ret, ['element']);

# Test.
$obj->put(
	['b', 'other_element'],
);
@ret = $obj->open_elements;
is_deeply(\@ret, ['other_element', 'element']);

# Test.
$obj->finalize;
@ret = $obj->open_elements;
is_deeply(\@ret, []);
