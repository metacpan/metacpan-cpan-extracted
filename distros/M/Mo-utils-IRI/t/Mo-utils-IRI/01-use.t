use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Mo::utils::IRI');
}

# Test.
require_ok('Mo::utils::IRI');
