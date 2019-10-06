#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testskyframe.f.

use strict;

use constant DPI => 3.1415926535897932384626433832795028842;

use Test::More tests => 4;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    my $sf1 = new Starlink::AST::SkyFrame('system=fk5,epoch=2015.0');
    isa_ok($sf1, 'Starlink::AST::SkyFrame');

    my @vals = (6.1, 6.15, 6.2, 6.25, 6.3);
    my $newval = $sf1->AxNorm(1, 0, \@vals);

    delta_ok($newval, [6.1, 6.15, 6.2, 6.25, 6.3 - 2 * DPI]);

    my $cross = $sf1->Intersect(
        [-0.1, 0],
        [0.1, 0],
        [0, -0.1],
        [0, 1.0]);
    delta_ok($cross, [0.0, 0.0]);
};

