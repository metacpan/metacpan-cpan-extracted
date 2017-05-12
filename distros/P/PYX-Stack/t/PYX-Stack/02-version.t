# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Stack;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Stack::VERSION, 0.04, 'Version.');
