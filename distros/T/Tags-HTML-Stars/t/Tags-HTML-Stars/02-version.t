use strict;
use warnings;

use Tags::HTML::Stars;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Stars::VERSION, 0.05, 'Version.');
