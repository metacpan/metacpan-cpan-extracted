use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Random::AcademicTitle::CZ;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Random::AcademicTitle::CZ->new;
isa_ok($obj, 'Random::AcademicTitle::CZ');

# Test.
$obj = Random::AcademicTitle::CZ->new(
	'old' => 1,
);
isa_ok($obj, 'Random::AcademicTitle::CZ');

# Test.
eval {
	Random::AcademicTitle::CZ->new(
		'old' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'old' must be a bool (0/1).\n",
	"Parameter 'old' must be a bool (0/1).");
clean();

# Test.
eval {
	Random::AcademicTitle::CZ->new(
		'bad' => 1,
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad'.\n",
	"Unknown parameter 'bad'.");
clean();
