#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testtrangrid.f.

use strict;

use Test::More tests => 4;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    my $c1 = new Starlink::AST::WinMap(
        [0.0, 0.0], [1.0, 1.0], [0.5, 0.5], [2.5, 2.5], '');
    isa_ok($c1, 'Starlink::AST::WinMap');

    my $c2 = $c1->Copy();
    isa_ok($c2, 'Starlink::AST::WinMap');

    my $m = new Starlink::AST::TranMap($c1, $c2, '');
    isa_ok($m, 'Starlink::AST::TranMap');
};

