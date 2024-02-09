use strict;
use warnings;

use Tags::HTML::Login::Register;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::Login::Register::VERSION, 0.08, 'Version.');
