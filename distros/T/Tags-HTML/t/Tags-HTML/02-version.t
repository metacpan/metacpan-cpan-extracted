use strict;
use warnings;

use Tags::HTML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::VERSION, 0.1, 'Version.');
