# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Task::WWW::Search::Antiquarian::Czech');
}

# Test.
require_ok('Task::WWW::Search::Antiquarian::Czech');
