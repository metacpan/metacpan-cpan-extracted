use strict;
use warnings;

use Tags::HTML::Tree;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Tree::VERSION, 0.07, 'Version.');
