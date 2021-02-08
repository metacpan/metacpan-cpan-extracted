use strict;
use warnings;

use Tags::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::Structure::VERSION, 0.06, 'Version.');
