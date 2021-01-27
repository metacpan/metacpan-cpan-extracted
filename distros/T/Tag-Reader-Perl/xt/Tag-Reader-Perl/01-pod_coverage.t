use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Tag::Reader::Perl', 'Tag::Reader::Perl is covered.');
