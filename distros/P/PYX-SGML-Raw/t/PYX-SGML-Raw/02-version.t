# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::SGML::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::SGML::Raw::VERSION, 0.02, 'Version.');
