use strict;
use warnings;

use Random::Day::InThePast;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Random::Day::InThePast::VERSION, 0.17, 'Version.');
