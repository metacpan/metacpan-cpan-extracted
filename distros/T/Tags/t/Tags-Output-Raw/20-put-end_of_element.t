# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use IO::Scalar;
use Tags::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
);
my $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['e', 'element'],
);
untie *STDOUT;
is($ret, '</element>', 'End of element');
$obj->reset;

# Test.
$obj = Tags::Output::Raw->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
	'xml' => 1,
);
eval {
	$obj->put(
		['e', 'element'],
	);
};
is($EVAL_ERROR, "Ending bad tag: 'element' doesn't begin.\n",
	"Ending bad tag: 'element' doesn't begin.");
$obj->reset;
