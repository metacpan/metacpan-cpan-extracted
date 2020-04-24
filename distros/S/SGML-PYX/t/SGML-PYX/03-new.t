use strict;
use warnings;

use SGML::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = SGML::PYX->new;
isa_ok($obj, 'SGML::PYX');
