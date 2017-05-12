# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use Tags::Output::PYX;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Output;

# Test.
my $obj = Tags::Output::PYX->new(
	'auto_flush' => 0,
	'output_handler' => \*STDOUT,
);
my $right_ret = <<'END';
(MAIN
-data
)MAIN
END
chomp $right_ret;
$obj->put(
	['b', 'MAIN'],
	['d', 'data'],
	['e', 'MAIN'],
);
stdout_is(
	sub {
		$obj->flush;
		return;
	},
	$right_ret,
	'Output to stdout.',
);

# Test.
$obj = Tags::Output::PYX->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
);
stdout_is(
	sub {
		$obj->put(
			['b', 'MAIN'],
			['d', 'data'],
			['e', 'MAIN'],
		);
		$obj->flush;
		return;
	},
	$right_ret,
	'Auto flush output to stdout.',
);
