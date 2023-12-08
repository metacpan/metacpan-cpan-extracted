use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Person::ID::CZ::RC', 'Person::ID::CZ::RC is covered.');
