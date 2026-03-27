use strict;
use warnings;

use NKC::Transform::MARC2RDA;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = NKC::Transform::MARC2RDA->new;
isa_ok($obj, 'NKC::Transform::MARC2RDA');
