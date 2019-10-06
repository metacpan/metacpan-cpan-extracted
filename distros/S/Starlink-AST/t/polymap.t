#!perl

# This is a Perl conversion of the ast_tester/testpolymap.f test program.

use strict;

use Test::More tests => 41;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    Starlink::AST::Begin();

    my @coeff = ( 1.0, 1.0, 0.0, 0.0,
                  2.0, 1.0, 1.0, 0.0,
                  1.0, 2.0, 0.0, 0.0,
                  3.0, 2.0, 0.0, 1.0 );

    my @coeff2 = ( 1.0, 1.0, 0.0, 0.0,
                   2.0, 1.0, 1.0, 0.0,
                   1.0, 1.0, 0.0, 1.0,
                   1.0, 2.0, 0.0, 0.0,
                   1.0, 2.0, 1.0, 0.0,
                   2.0, 2.0, 0.0, 1.0 );

    my @coeff3 = ( -0.1,     1.0, 0.0, 0.0,
                   0.99,     1.0, 1.0, 0.0,
                   1.0E-4,   1.0, 1.0, 1.0,
                   -0.1,     2.0, 0.0, 0.0,
                   0.99,     2.0, 0.0, 1.0,
                   1.0E-4,   2.0, 1.0, 1.0 );

    my @coeff_1d = ( 1.0, 1.0, 0.0,
                     2.0, 1.0, 1.0 );

    my @lbnd = ( -10.0e2, -10.0e2 );
    my @ubnd = ( 10.0e2, 10.0e2 );

    my $acc = 1.0e-7;
    my $errlim = 1000 * $acc;
    my $maxacc = 1.0e-3;
    my $maxord = 10;

    my $pm = new Starlink::AST::PolyMap( 2, 2, \@coeff, [], ' ' );
    isa_ok($pm, 'Starlink::AST::PolyMap');

    my ($cofs, $nco) = $pm->PolyCoeffs( 0 );
    is($nco, 0);

    my ($cofs, $nco) = $pm->PolyCoeffs( 1 );
    is($nco, 4);
    delta_ok($cofs, \@coeff);

    my $pm2 = $pm->PolyTran( 0, $acc, $maxacc, $maxord, \@lbnd, \@ubnd );
    isa_ok($pm2, 'Starlink::AST::PolyMap');

    my @xin = ( 1.0, 100.0, -50.0 );
    my @yin = ( 1.0, 100.0, -50.0 );

    my ($xout, $yout) = $pm2->Tran2( \@xin, \@yin, 1 );
    my ($xin2, $yin2) = $pm2->Tran2( $xout, $yout, 0 );

    delta_within(\@xin, $xin2, $errlim);
    delta_within(\@yin, $yin2, $errlim);

    $pm2->SetL( 'IterInverse', 1 );
    ($xin2, $yin2) = $pm2->Tran2( $xout, $yout, 0 );

    delta_within(\@xin, $xin2, $errlim);
    delta_within(\@yin, $yin2, $errlim);

    $pm = new Starlink::AST::PolyMap( 1, 1, \@coeff_1d, [], ' ' );
    isa_ok($pm, 'Starlink::AST::PolyMap');

    $pm2 = $pm->PolyTran( 0, $acc, $maxacc, $maxord, [$lbnd[0]], [$ubnd[0]] );
    isa_ok($pm2, 'Starlink::AST::PolyMap');

    @xin = ( 1.0, 100.0, -50.0 );

    $xout = $pm2->Tran1( \@xin, 1 );
    $xin2 = $pm2->Tran1( $xout, 0 );

    delta_within($xin2, \@xin, $errlim);

    $pm2->SetL( 'IterInverse', 1 );
    $xin2 = $pm2->Tran1( $xout, 0 );

    delta_within($xin2, \@xin, $errlim);

    $pm = new Starlink::AST::PolyMap( 2, 2, \@coeff2, [], ' ' );
    isa_ok($pm, 'Starlink::AST::PolyMap');

    $pm2 = $pm->PolyTran( 0, $acc, $maxacc, $maxord, \@lbnd, \@ubnd );
    isa_ok($pm2, 'Starlink::AST::PolyMap');

    @xin = ( 1.0, 100.0, -50.0 );
    @yin = ( 1.0, 100.0, -50.0 );

    ($xout, $yout) = $pm2->Tran2( \@xin, \@yin, 1 );
    ($xin2, $yin2) = $pm2->Tran2( $xout, $yout, 0 );

    delta_within($xin2, \@xin, $errlim);
    delta_within($yin2, \@yin, $errlim);

    $pm2->SetL( 'IterInverse', 1 );
    ($xin2, $yin2) = $pm2->Tran2( $xout, $yout, 0 );

    delta_within($xin2, \@xin, $errlim);
    delta_within($yin2, \@yin, $errlim);

    $pm = new Starlink::AST::PolyMap( 2, 2, \@coeff3, [], ' ' );
    isa_ok($pm, 'Starlink::AST::PolyMap');
    $pm2 = $pm->PolyTran( 0, $acc, $maxacc, $maxord, \@lbnd, \@ubnd );
    isa_ok($pm2, 'Starlink::AST::PolyMap');

    @xin = ( 1.0, 100.0, -50.0 );
    @yin = ( 1.0, 100.0, -50.0 );

    ($xout, $yout) = $pm2->Tran2( \@xin, \@yin, 1 );
    ($xin2, $yin2) = $pm2->Tran2( $xout, $yout, 0 );

    delta_within($xin2, \@xin, $errlim);
    delta_within($yin2, \@yin, $errlim);

    $pm2->SetL( 'IterInverse', 1 );
    ($xin2, $yin2) = $pm2->Tran2( $xout, $yout, 0 );

    delta_within($xin2, \@xin, $errlim);
    delta_within($yin2, \@yin, $errlim);

    ok($pm->GetL('TranForward'));
    ok($pm->GetL('IterInverse'));
    ok($pm->GetL('TranInverse'));

    $pm->SetL( 'IterInverse', 0 );

    ok($pm->GetL('TranForward'));
    ok(not $pm->GetL('IterInverse'));
    ok(not $pm->GetL('TranInverse'));

    $pm->Invert();

    ok(not $pm->GetL('TranForward'));
    ok(not $pm->GetL('IterInverse'));
    ok($pm->GetL('TranInverse'));

    $pm->SetL( 'IterInverse', 1 );

    ok($pm->GetL('TranForward'));
    ok($pm->GetL('IterInverse'));
    ok($pm->GetL('TranInverse'));

    $pm->Invert();

    ok($pm->GetL('TranForward'));
    ok($pm->GetL('IterInverse'));
    ok($pm->GetL('TranInverse'));
};
