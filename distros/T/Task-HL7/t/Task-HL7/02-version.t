# Pragmas.
use strict;
use warnings;

# Modules.
use Task::HL7;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::HL7::VERSION, 0.02, 'Version.');
