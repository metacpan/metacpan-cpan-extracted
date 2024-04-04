use strict;
use warnings;

use Number::Stars;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Number::Stars::VERSION, 0.03, 'Version.');
