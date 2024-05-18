use strict;
use warnings;

use Tags::HTML::Login::Access;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Login::Access::VERSION, 0.13, 'Version.');
