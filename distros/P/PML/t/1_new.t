#!perl
## Test Script for PML new

use strict;
use Test;

BEGIN {plan tests => 2}

use PML;

ok(1);

#  Test to see if new works
my $parser = new PML {PML => 'YES'};
ok($parser->[PML::PML_V]{PML}, 'YES');
