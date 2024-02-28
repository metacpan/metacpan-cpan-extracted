use strict;
use warnings;

use Tags::HTML::ChangePassword;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::ChangePassword::VERSION, 0.04, 'Version.');
