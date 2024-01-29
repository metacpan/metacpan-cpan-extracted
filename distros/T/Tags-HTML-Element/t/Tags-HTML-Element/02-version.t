use strict;
use warnings;

use Tags::HTML::Element;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::VERSION, 0.02, 'Version.');
