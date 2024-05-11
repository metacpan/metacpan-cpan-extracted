use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Tags::HTML::Navigation::Grid');
}

# Test.
require_ok('Tags::HTML::Navigation::Grid');
