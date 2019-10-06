#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testswitchmap.f.

use strict;

use Test::More tests => 19;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    my $wm1 = new Starlink::AST::WinMap([1.0], [101.0], [1000.0], [2000.0], '');
    isa_ok($wm1, 'Starlink::AST::WinMap');

    my $pm1 = new Starlink::AST::PermMap([1, -1], [1], [1.0], '');
    isa_ok($pm1, 'Starlink::AST::PermMap');

    my $rm1 = new Starlink::AST::CmpMap($pm1, $wm1, 1, '');
    isa_ok($rm1, 'Starlink::AST::CmpMap');

    my $wm2 = new Starlink::AST::WinMap([1.0], [101.0], [1600.0], [2700.0], '');
    isa_ok($wm2, 'Starlink::AST::WinMap');

    my $pm2 = new Starlink::AST::PermMap([1, -1], [1], [2.0], '');
    isa_ok($pm2, 'Starlink::AST::PermMap');

    my $rm2 = new Starlink::AST::CmpMap($pm2, $wm2, 1, '');
    isa_ok($rm2, 'Starlink::AST::CmpMap');

    my $fs = new Starlink::AST::PermMap([0, 1], [2], [0.0], '');
    isa_ok($fs, 'Starlink::AST::PermMap');

    my $is = new Starlink::AST::MathMap(1, 1, ['y'], ['x=qif(y>1800,2,1)'], '');
    isa_ok($is, 'Starlink::AST::MathMap');

    my $swm = new Starlink::AST::SwitchMap($fs, $is, [$rm1, $rm2], '');
    isa_ok($swm, 'Starlink::AST::SwitchMap');
};

do {
    my @card = (
        'CRPIX1  = 45',
        'CRPIX2  = 45',
        'CRVAL1  = 45',
        'CRVAL2  = 89.9',
        'CDELT1  = -0.01',
        'CDELT2  = 0.01',
        "CTYPE1  = 'RA---TAN'",
        "CTYPE2  = 'DEC--TAN'",
    );

    my $fc = new Starlink::AST::FitsChan();
    isa_ok($fc, 'Starlink::AST::FitsChan');
    $fc->PutFits($_, 0) foreach @card;
    $fc->Clear('Card');
    my $fs = $fc->Read();
    isa_ok($fs, 'Starlink::AST::FrameSet');
    my $rm1 = $fs->GetMapping(Starlink::AST::AST__BASE(), Starlink::AST::AST__CURRENT());
    isa_ok($rm1, 'Starlink::AST::Mapping');

    $card[0] = 'CRPIX1  = 135';
    $fc->Clear('Card');
    $fc->PutFits($_, 1) foreach @card;
    $fc->Clear('Card');
    $fs = $fc->Read();
    isa_ok($fs, 'Starlink::AST::FrameSet');
    my $rm2 = $fs->GetMapping(Starlink::AST::AST__BASE(), Starlink::AST::AST__CURRENT());
    isa_ok($rm2, 'Starlink::AST::Mapping');

    my $gridframe = $fs->GetFrame(Starlink::AST::AST__BASE());
    isa_ok($gridframe, 'Starlink::AST::Frame');

    my $box1 = new Starlink::AST::Box($gridframe, 1, [10, 80], [10, 80], undef, '');
    isa_ok($box1, 'Starlink::AST::Box');

    my $box2 = new Starlink::AST::Box($gridframe, 1, [100, 10], [170, 80], undef, '');
    isa_ok($box2, 'Starlink::AST::Box');

    my $selmap = new Starlink::AST::SelectorMap([$box1, $box2], Starlink::AST::AST__BAD(), '');
    isa_ok($selmap, 'Starlink::AST::SelectorMap');
};
