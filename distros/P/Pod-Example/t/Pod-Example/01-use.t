use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Pod::Example');
}

# Test.
require_ok('Pod::Example');
