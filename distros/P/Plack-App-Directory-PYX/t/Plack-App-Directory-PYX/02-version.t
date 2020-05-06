use strict;
use warnings;

use Plack::App::Directory::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Directory::PYX::VERSION, 0.03, 'Version.');
