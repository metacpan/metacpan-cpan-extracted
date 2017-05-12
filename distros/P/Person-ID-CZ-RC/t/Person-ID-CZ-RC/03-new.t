# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Person::ID::CZ::RC;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
eval {
	Person::ID::CZ::RC->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Person::ID::CZ::RC->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Person::ID::CZ::RC->new;
};
is($EVAL_ERROR, "Parameter 'rc' is required.\n",
	"Parameter 'rc' is required.");
clean();

# Test.
my $obj = Person::ID::CZ::RC->new(
	'rc' => 'foo',
);
isa_ok($obj, 'Person::ID::CZ::RC');
