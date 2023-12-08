use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Person::ID::CZ::RC::Generator;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
eval {
	Person::ID::CZ::RC::Generator->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Person::ID::CZ::RC::Generator->new;
isa_ok($obj, 'Person::ID::CZ::RC::Generator');

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'rc_sep' => 'X',
	);
};
is($EVAL_ERROR, "Parameter 'rc_sep' has bad value.\n",
	"Parameter 'rc_sep' has bad value.");

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'serial' => 1000,
	);
};
is($EVAL_ERROR, "Parameter 'serial' is greater than 999.\n",
	"Parameter 'serial' is greater than 999.");

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'serial' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'serial' is lesser than 1.\n",
	"Parameter 'serial' is lesser than 1.");

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'serial' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'serial' isn't number.\n",
	"Parameter 'serial' isn't number.");

# Test.
$obj = Person::ID::CZ::RC::Generator->new(
	'serial' => 100,
);
isa_ok($obj, 'Person::ID::CZ::RC::Generator');

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'sex' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'sex' has bad value.\n",
	"Parameter 'sex' has bad value.");

# Test.
$obj = Person::ID::CZ::RC::Generator->new(
	'sex' => 'male',
);
isa_ok($obj, 'Person::ID::CZ::RC::Generator');

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'year' => '1850',
	);
};
is($EVAL_ERROR, "Parameter 'year' is lesser than 1855.\n",
	"Parameter 'year' is lesser than 1855.");

# Test.
eval {
	Person::ID::CZ::RC::Generator->new(
		'year' => '2100',
	);
};
is($EVAL_ERROR, "Parameter 'year' is greater than 2054.\n",
	"Parameter 'year' is greater than 2054.");

# Test.
$obj = Person::ID::CZ::RC::Generator->new(
	'year' => 1950,
);
isa_ok($obj, 'Person::ID::CZ::RC::Generator');
