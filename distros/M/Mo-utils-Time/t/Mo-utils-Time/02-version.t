use strict;
use warnings;

use Mo::utils::Time;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Time::VERSION, 0.01, 'Version.');
