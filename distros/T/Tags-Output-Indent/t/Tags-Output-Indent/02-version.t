use strict;
use warnings;

use Tags::Output::Indent;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::Indent::VERSION, 0.1, 'Version.');
