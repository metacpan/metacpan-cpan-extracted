use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Plack::Middleware::Auth::OAuth2');
}

# Test.
require_ok('Plack::Middleware::Auth::OAuth2');
