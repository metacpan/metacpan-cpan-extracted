use strict;
use warnings;

use Tags::HTML::Element::A;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::A::VERSION, 0.11, 'Version.');
