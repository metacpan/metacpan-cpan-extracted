# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Format;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Format::VERSION, 0.05, 'Version.');
