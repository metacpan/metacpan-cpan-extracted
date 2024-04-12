use strict;
use warnings;

use Mo::utils::Country;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Country::VERSION, 0.02, 'Version.');
