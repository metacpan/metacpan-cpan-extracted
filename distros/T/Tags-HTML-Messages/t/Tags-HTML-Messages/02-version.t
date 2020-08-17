use strict;
use warnings;

use Tags::HTML::Messages;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Messages::VERSION, 0.02, 'Version.');
