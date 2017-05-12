# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Mock::Person;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Mock::Person::VERSION, 0.03, 'Version.');
