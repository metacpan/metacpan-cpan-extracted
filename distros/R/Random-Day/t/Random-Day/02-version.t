use strict;
use warnings;

use Random::Day;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Random::Day::VERSION, 0.13, 'Version.');
