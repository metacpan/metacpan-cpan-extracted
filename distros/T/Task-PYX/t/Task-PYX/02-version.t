# Pragmas.
use strict;
use warnings;

# Modules.
use Task::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::PYX::VERSION, 0.09, 'Version.');
