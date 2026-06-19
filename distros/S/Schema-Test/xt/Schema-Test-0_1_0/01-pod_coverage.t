use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Schema::Test::0_1_0', 'Schema::Test::0_1_0 is covered.');
