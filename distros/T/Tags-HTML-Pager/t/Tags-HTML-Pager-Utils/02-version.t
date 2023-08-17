use strict;
use warnings;

use Tags::HTML::Pager::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Pager::Utils::VERSION, 0.05, 'Version.');
