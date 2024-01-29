use strict;
use warnings;

use Plack::App::Register;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Register::VERSION, 0.03, 'Version.');
