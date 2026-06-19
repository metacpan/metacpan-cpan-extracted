use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Schema::Test::0_3_0::Result::Address');
}

# Test.
require_ok('Schema::Test::0_3_0::Result::Address');
