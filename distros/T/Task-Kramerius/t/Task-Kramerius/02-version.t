use strict;
use warnings;

use Task::Kramerius;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Kramerius::VERSION, 0.01, 'Version.');
