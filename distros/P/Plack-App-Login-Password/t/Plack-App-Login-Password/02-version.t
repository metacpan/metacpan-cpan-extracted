use strict;
use warnings;

use Plack::App::Login::Password;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Login::Password::VERSION, 0.02, 'Version.');
