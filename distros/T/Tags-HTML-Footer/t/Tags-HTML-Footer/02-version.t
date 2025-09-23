use strict;
use warnings;

use Tags::HTML::Footer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Footer::VERSION, 0.04, 'Version.');
