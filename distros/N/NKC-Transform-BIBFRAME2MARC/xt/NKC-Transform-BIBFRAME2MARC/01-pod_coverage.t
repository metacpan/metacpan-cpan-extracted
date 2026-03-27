use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('NKC::Transform::BIBFRAME2MARC', 'NKC::Transform::BIBFRAME2MARC is covered.');
