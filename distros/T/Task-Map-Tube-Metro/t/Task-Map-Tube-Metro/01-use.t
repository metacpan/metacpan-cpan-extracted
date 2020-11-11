use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Task::Map::Tube::Metro');
}

# Test.
require_ok('Task::Map::Tube::Metro');
