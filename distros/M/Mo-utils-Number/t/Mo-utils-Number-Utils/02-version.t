use strict;
use warnings;

use Mo::utils::Number::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Number::Utils::VERSION, 0.04, 'Version.');
