use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Tags::HTML::Table::View', 'Tags::HTML::Table::View is covered.');
