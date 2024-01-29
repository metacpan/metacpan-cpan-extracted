use strict;
use warnings;

use Tags::HTML::Element::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::Utils::VERSION, 0.02, 'Version.');
