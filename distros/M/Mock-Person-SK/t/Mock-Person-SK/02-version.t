# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mock::Person::SK::VERSION, 0.04, 'Version.');
