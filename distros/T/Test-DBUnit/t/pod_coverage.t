use strict;
use warnings;

use Test::Pod::Coverage tests=>2;
pod_coverage_ok( "DBUnit", "should have DBUnit coverage");
pod_coverage_ok( "Test::DBUnit", "should have Test::DBUnit coverage");