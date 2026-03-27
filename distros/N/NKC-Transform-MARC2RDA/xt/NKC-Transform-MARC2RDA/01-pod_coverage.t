use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('NKC::Transform::MARC2RDA', 'NKC::Transform::MARC2RDA is covered.');
