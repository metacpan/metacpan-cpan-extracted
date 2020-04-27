use strict;
use warnings;

use PYX::SGML::Tags;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::SGML::Tags::VERSION, 0.04, 'Version.');
