use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Plack::App::CPAN::Changes', 'Plack::App::CPAN::Changes is covered.');
