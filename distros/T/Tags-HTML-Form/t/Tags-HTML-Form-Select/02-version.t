use strict;
use warnings;

use Tags::HTML::Form::Select;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Form::Select::VERSION, 0.05, 'Version.');
