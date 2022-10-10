use strict;
use warnings;

use Schema::Data::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Data::Data::VERSION, 0.04, 'Version.');
