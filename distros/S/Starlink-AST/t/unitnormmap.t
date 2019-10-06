#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testunitnormmap.f.

use strict;

use Test::More tests => 2;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    my $map = new Starlink::AST::UnitNormMap([-1.0, 1.0, 2.0], '');
    isa_ok($map, 'Starlink::AST::UnitNormMap');
};
