use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Plack::App::Login::Password');
}

# Test.
require_ok('Plack::App::Login::Password');
