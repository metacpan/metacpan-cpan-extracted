use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('SysV::Init::Service', 'SysV::Init::Service is covered.');
