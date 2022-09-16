use strict;
use warnings;

use Plack::Middleware::Auth::OAuth2;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::Middleware::Auth::OAuth2::VERSION, 0.01, 'Version.');
