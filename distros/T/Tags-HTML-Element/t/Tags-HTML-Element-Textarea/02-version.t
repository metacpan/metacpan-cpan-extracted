use strict;
use warnings;

use Tags::HTML::Element::Textarea;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::Textarea::VERSION, 0.09, 'Version.');
