use strict;
use warnings;

use Random::AcademicTitle::CZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Random::AcademicTitle::CZ::VERSION, 0.03, 'Version.');
