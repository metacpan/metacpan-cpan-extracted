use strict;
use warnings;

use Tags::HTML::Image::Grid;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Image::Grid::VERSION, 0.01, 'Version.');
