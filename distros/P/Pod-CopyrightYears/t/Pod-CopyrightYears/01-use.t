use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Pod::CopyrightYears');
}

# Test.
require_ok('Pod::CopyrightYears');
