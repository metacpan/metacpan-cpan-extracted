use strict;
use warnings;

use Pod::Example;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Pod::Example::VERSION, 0.14, 'Version.');
