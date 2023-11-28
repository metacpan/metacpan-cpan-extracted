use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Task::Error::Pure');
}

# Test.
require_ok('Task::Error::Pure');
