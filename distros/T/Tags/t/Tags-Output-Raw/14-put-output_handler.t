use strict;
use warnings;

use File::Object;
use Tags::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Include helpers.
do File::Object->new->up->file('get_stdout.inc')->s;

# Test.
my $obj = Tags::Output::Raw->new(
	'output_handler' => \*STDOUT,
	'xml' => 0,
);
my $ret = get_stdout($obj, 1, ['b', 'MAIN'], ['d', 'data'], ['e', 'MAIN']);
is($ret, '<MAIN>data</MAIN>');

# Test.
$obj = Tags::Output::Raw->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
	'xml' => 0,
);
$ret = get_stdout($obj, 1, ['b', 'MAIN'], ['d', 'data'], ['e', 'MAIN']);
is($ret, '<MAIN>data</MAIN>');
