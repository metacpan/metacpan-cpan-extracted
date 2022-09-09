use strict;
use warnings;

use Schema::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Data::VERSION, 0.03, 'Version.');
