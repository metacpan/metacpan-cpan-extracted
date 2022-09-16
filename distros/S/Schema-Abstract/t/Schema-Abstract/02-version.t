use strict;
use warnings;

use Schema::Abstract;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Abstract::VERSION, 0.04, 'Version.');
