use strict;
use warnings;

use Mo::utils::Date;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Date::VERSION, 0.03, 'Version.');
