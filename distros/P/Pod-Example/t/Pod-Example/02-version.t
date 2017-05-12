# Pragmas.
use strict;
use warnings;

# Modules.
use Pod::Example;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Pod::Example::VERSION, 0.08, 'Version.');
