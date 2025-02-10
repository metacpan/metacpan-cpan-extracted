use strict;
use warnings;

use Tags::HTML::Icon;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Icon::VERSION, 0.01, 'Version.');
