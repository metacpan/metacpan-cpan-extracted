use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Tags::HTML::Page::Begin;

# Test.
is($Tags::HTML::Page::Begin::VERSION, 0.11, 'Version.');
