use strict;
use warnings;

use Mo::utils::TimeZone;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::TimeZone::VERSION, 0.03, 'Version.');
