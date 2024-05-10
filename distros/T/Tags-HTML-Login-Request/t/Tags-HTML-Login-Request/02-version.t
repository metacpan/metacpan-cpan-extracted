use strict;
use warnings;

use Tags::HTML::Login::Request;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Login::Request::VERSION, 0.02, 'Version.');
