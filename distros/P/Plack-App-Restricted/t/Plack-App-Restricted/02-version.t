use strict;
use warnings;

use Plack::App::Restricted;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Restricted::VERSION, 0.01, 'Version.');
