use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Pod::CopyrightYears', 'Pod::CopyrightYears is covered.');
