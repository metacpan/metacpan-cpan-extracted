use strict;
use warnings;

use Task::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::PYX::VERSION, 0.1, 'Version.');
