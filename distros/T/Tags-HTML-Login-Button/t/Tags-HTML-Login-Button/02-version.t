use strict;
use warnings;

use Tags::HTML::Login::Button;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Login::Button::VERSION, 0.04, 'Version.');
