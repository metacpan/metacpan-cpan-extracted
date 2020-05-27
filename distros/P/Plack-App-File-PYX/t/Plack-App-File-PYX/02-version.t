use strict;
use warnings;

use Plack::App::File::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::File::PYX::VERSION, 0.01, 'Version.');
