use strict;
use warnings;

use Task::Graph::Reader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Graph::Reader::VERSION, 0.04, 'Version.');
