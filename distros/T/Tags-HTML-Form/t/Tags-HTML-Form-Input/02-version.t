use strict;
use warnings;

use Tags::HTML::Form::Input;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Form::Input::VERSION, 0.03, 'Version.');
