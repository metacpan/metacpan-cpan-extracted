use strict;
use warnings;

use Plack::App::Redirect;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Redirect::VERSION, 0.02, 'Version.');
