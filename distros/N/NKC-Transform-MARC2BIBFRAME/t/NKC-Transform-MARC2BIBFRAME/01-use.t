use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('NKC::Transform::MARC2BIBFRAME');
}

# Test.
require_ok('NKC::Transform::MARC2BIBFRAME');
