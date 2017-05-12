# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('PYX::XMLNorm');
}

# Test.
require_ok('PYX::XMLNorm');
