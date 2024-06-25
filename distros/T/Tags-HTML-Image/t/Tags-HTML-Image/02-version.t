use strict;
use warnings;

use Tags::HTML::Image;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Image::VERSION, 0.03, 'Version.');
