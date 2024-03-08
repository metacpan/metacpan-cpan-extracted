use strict;
use warnings;

use Tags::HTML::Container;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Container::VERSION, 0.05, 'Version.');
