use strict;
use warnings;

use Tags::HTML::Page::Begin;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Page::Begin::VERSION, 0.16, 'Version.');
