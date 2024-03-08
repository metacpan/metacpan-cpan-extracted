use strict;
use warnings;

use Tags::HTML::Element::Option;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::Option::VERSION, 0.09, 'Version.');
