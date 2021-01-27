use strict;
use warnings;

use Tag::Reader::Perl;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tag::Reader::Perl::VERSION, 0.02, 'Version.');
