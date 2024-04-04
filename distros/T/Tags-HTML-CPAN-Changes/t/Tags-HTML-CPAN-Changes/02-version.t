use strict;
use warnings;

use Tags::HTML::CPAN::Changes;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::CPAN::Changes::VERSION, 0.03, 'Version.');
