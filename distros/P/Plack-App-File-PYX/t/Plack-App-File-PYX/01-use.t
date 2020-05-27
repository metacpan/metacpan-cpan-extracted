use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Plack::App::File::PYX');
}

# Test.
require_ok('Plack::App::File::PYX');
