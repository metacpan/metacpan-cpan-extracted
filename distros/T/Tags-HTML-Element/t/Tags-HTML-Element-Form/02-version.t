use strict;
use warnings;

use Tags::HTML::Element::Form;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Element::Form::VERSION, 0.11, 'Version.');
