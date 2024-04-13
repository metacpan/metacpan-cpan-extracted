use strict;
use warnings;

use Tags::HTML::Element::Select;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::Select::VERSION, 0.1, 'Version.');
