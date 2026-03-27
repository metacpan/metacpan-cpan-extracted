use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('NKC::Transform::MARC2BIBFRAME', 'NKC::Transform::MARC2BIBFRAME is covered.');
