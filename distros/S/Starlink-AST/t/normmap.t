#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testnormmap.f.

use strict;

use Test::More tests => 5;

require_ok('Starlink::AST');

do {
    my $f = new Starlink::AST::CmpFrame(
        new Starlink::AST::SpecFrame(''),
        new Starlink::AST::SkyFrame(''),
        '');
    isa_ok($f, 'Starlink::AST::CmpFrame');
    $f->PermAxes([3, 1, 2]);

    my $m = new Starlink::AST::NormMap($f, '');
    isa_ok($m, 'Starlink::AST::NormMap');

    is($m->GetI('Nin'), 3);
    is($m->GetI('Nout'), 3);
};
