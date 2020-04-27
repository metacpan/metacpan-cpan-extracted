use strict;
use warnings;

use IO::Scalar;
use Tags::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'output_handler' => \*STDOUT,
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['d', 'data'],
	['e', 'MAIN'],
);
my $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->flush;
untie *STDOUT;
is($ret, '<MAIN>data</MAIN>', 'Test STDOUT output handler with explicit flush.');
undef $ret;

# Test.
$obj = Tags::Output::Raw->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
	'xml' => 0,
);
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['b', 'MAIN'],
	['d', 'data'],
	['e', 'MAIN'],
);
untie *STDOUT;
is($ret, '<MAIN>data</MAIN>', 'Test STDOUT output handler with auto-flush.');
undef $ret;
