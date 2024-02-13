use strict;
use warnings;

use Plack::App::ChangePassword;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::ChangePassword::VERSION, 0.03, 'Version.');
