use strict;
use warnings;

use File::Object;
use IO::Scalar;
use Tags::Output::Raw;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
	'xml' => 1,
);
my $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['b', 'element'],
	['e', 'element'],
);
untie *STDOUT;
is($ret, '<element />');

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(['b', 'element']);
$obj->put(['e', 'element']);
untie *STDOUT;
is($ret, '<element />');

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['b', 'element'],
	['d', 'data'],
	['e', 'element'],
);
untie *STDOUT;
is($ret, '<element>data</element>');

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['b', 'element'],
	['b', 'other_element'],
	['d', 'data'],
	['e', 'other_element'],
	['e', 'element'],
);
untie *STDOUT;
is($ret, '<element><other_element>data</other_element></element>');

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(['b', 'element']);
$obj->put(['b', 'other_element']);
$obj->put(['d', 'data']);
$obj->put(['e', 'other_element']);
$obj->put(['e', 'element']);
untie *STDOUT;
is($ret, '<element><other_element>data</other_element></element>');
