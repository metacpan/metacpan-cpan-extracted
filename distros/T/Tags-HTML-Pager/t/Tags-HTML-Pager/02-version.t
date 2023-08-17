use strict;
use warnings;

use Tags::HTML::Pager;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Pager::VERSION, 0.05, 'Version.');
