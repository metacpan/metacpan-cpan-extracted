use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Plack::Component::Tags::HTML');
}

# Test.
require_ok('Plack::Component::Tags::HTML');
