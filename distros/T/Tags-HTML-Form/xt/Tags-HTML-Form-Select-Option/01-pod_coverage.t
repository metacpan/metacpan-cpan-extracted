use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Tags::HTML::Form::Select::Option', 'Tags::HTML::Form::Select::Option is covered.');
