# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::PYX::VERSION, 0.03, 'Version.');
