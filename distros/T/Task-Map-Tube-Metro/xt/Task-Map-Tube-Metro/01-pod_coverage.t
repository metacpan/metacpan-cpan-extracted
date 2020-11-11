use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Task::Map::Tube::Metro', 'Task::Map::Tube::Metro is covered.');
