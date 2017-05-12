# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::EN;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mock::Person::EN::VERSION, 0.04, 'Version.');
