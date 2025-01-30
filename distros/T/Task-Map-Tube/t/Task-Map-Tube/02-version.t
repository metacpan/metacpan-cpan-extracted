use strict;
use warnings;

use Task::Map::Tube;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Map::Tube::VERSION, 0.49, 'Version.');
