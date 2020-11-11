use strict;
use warnings;

use Task::Map::Tube::Metro;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Map::Tube::Metro::VERSION, 0.13, 'Version.');
