use strict;
use warnings;

use Tags::HTML::Table::View;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Table::View::VERSION, 0.07, 'Version.');
