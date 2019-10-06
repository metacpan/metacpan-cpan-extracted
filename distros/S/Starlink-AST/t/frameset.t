#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testframeset.f.

use strict;

use Test::More tests => 10;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    my $pfrm = new Starlink::AST::Frame(2, 'Domain=PIXEL');
    isa_ok($pfrm, 'Starlink::AST::Frame');

    my $ffrm = new Starlink::AST::Frame(2, 'Domain=FPLANE');
    isa_ok($ffrm, 'Starlink::AST::Frame');

    my $p2fmap = new Starlink::AST::WinMap(
        [1.0, 1.0], [100.0, 200.0], [-2.5, -1.0], [2.5, 1.0], '');
    isa_ok($p2fmap, 'Starlink::AST::WinMap');

    my $fs = new Starlink::AST::FrameSet($pfrm, '');
    isa_ok($fs, 'Starlink::AST::FrameSet');

    $fs->AddFrame(Starlink::AST::AST__CURRENT(), $p2fmap, $ffrm);

    $fs->SetC('Base', 'Fplane');
    is($fs->GetI('Base'), 2);

    $fs->SetC('Base', 'Pixel');
    is($fs->GetI('Base'), 1);

    $fs->SetC('Current', 'Pixel');
    is($fs->GetI('Current'), 1);

    $fs->SetC('Current', 'fplane');
    is($fs->GetI('Current'), 2);

    $fs->AddVariant(undef, 'FP1');
    is($fs->GetC('AllVariants'), 'FP1');

    $fs->MirrorVariants(1);
}
