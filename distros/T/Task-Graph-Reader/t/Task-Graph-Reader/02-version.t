# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Graph::Reader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Graph::Reader::VERSION, 0.03, 'Version.');
