use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Number::Stars;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Number::Stars->new;
isa_ok($obj, 'Number::Stars');

# Test.
eval {
	Number::Stars->new(
		'bad_param' => 'foo',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad_param'.\n",
	"Unknown parameter 'bad_param'.");
clean();

# Test.
$obj = Number::Stars->new(
	'number_of_stars' => 3,
);
isa_ok($obj, 'Number::Stars');

# Test.
eval {
	Number::Stars->new(
		'number_of_stars' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'number_of_stars' must be a number.\n",
	"Parameter 'number_of_stars' must be a number.");
clean();
