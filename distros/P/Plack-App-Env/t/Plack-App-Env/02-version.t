use strict;
use warnings;

use Plack::App::Env;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Env::VERSION, 0.09, 'Version.');
