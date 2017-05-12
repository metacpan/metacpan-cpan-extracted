# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Person::ID::CZ::RC');
}

# Test.
require_ok('Person::ID::CZ::RC');
