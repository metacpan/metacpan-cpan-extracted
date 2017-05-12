# Pragmas.
use strict;
use warnings;

# Modules.
use Tag::Reader::Perl;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tag::Reader::Perl::VERSION, 0.01, 'Version.');
