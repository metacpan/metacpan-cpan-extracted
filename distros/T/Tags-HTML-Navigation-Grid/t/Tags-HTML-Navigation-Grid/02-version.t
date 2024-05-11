use strict;
use warnings;

use Tags::HTML::Navigation::Grid;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Navigation::Grid::VERSION, 0.02, 'Version.');
