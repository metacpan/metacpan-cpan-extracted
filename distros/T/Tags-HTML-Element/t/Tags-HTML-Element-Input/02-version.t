use strict;
use warnings;

use Tags::HTML::Element::Input;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::Input::VERSION, 0.08, 'Version.');
