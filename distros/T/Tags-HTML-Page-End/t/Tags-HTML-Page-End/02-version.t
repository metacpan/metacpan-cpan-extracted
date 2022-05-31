use strict;
use warnings;

use Tags::HTML::Page::End;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Page::End::VERSION, 0.05, 'Version.');
