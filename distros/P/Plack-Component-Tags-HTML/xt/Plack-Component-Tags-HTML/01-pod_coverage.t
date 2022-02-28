use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Plack::Component::Tags::HTML', 'Plack::Component::Tags::HTML is covered.');
