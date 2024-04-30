use strict;
use warnings;

use Plack::App::Login::Request;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Login::Request::VERSION, 0.01, 'Version.');
