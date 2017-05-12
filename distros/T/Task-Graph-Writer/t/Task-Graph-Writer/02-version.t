# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Graph::Writer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Graph::Writer::VERSION, 0.02, 'Version.');
