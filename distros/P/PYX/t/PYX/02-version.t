# Pragmas.
use strict;
use warnings;

# Modules.
use PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::VERSION, 0.05, 'Version.');
