use strict;
use warnings;

use Mo::utils::EAN;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::EAN::VERSION, 0.01, 'Version.');
