use strict;
use warnings;

use Tags::HTML::Form;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Form::VERSION, 0.08, 'Version.');
