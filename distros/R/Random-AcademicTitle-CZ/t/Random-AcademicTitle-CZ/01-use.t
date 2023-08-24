use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Random::AcademicTitle::CZ');
}

# Test.
require_ok('Random::AcademicTitle::CZ');
