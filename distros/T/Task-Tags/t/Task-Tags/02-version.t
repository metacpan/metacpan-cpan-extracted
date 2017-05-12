# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Tags;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Tags::VERSION, 0.06, 'Version.');
