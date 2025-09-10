use strict;
use warnings;

use Mo::utils::Number::Range;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Number::Range::VERSION, 0.07, 'Version.');
