use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('NKC::Transform::BIBFRAME2MARC::Utils', 'NKC::Transform::BIBFRAME2MARC::Utils is covered.');
