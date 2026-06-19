use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Schema::Test::0_2_0::Result::Person', 'Schema::Test::0_2_0::Result::Person is covered.');
