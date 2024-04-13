use strict;
use warnings;

use Tags::HTML::Element::Button;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::Button::VERSION, 0.1, 'Version.');
