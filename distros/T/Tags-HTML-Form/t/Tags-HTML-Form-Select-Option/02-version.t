use strict;
use warnings;

use Tags::HTML::Form::Select::Option;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Form::Select::Option::VERSION, 0.07, 'Version.');
