#!perl

# This is a Perl conversion of the ast_tester/testchebymap.f test program.

use strict;

use Test::More tests => 49 + 5 * 6 + 3 * 1 + 8 * 4;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    Starlink::AST::Begin();

    # f(x) = 1.5*T0(x') - 1.0*T2(x') + 2.0*T3(x') - 1.3*T4(x')
    my @coeffs_1  = ( 1.5, 1.0, 0.0,
                     -1.0, 1.0, 2.0,
                      2.0, 1.0, 3.0,
                      1.3, 1.0, 4.0 );

    # f(x) = 1.0*T0(x') - 2.0*T1(x')
    my @coeffs_2 = ( 1.0, 1.0, 0.0,
                    -2.0, 1.0, 1.0 );

    # fx(x,y) = 1.0*T0(x')*T0(y') - 2.0*T1(x')*T2(y') + T1(y')
    # fy(x,y) = 1.5*T0(x')*T0(y') - 2.5*T1(x')*T2(y')
    my @coeffs_3 = ( 1.0, 1.0, 0.0, 0.0,
                    -2.0, 1.0, 1.0, 2.0,
                     1.0, 1.0, 0.0, 1.0,
                     1.5, 2.0, 0.0, 0.0,
                    -2.5, 2.0, 1.0, 2.0 );

    # fx(x,y) = T1(x') + T1(y')
    # fy(x,y) = T1(x') - T1(y')

    # This has the property that the coeffs of the inverse transformation are
    # equal to the coeffs of the forward transformation.
    my @coeffs_4 = ( 1.0, 1.0, 1.0, 0.0,
                     1.0, 1.0, 0.0, 1.0,
                     1.0, 2.0, 1.0, 0.0,
                    -1.0, 2.0, 0.0, 1.0 );

    # One-dimensional ChebyMaps, order 1: a constant equal to 1.5
    my @lbnd = (-1.0, -1.0);
    my @ubnd = (1.0, 1.0);

    my $cm = new Starlink::AST::ChebyMap(
        1, 1, [@coeffs_1[0 .. 2]], [], [$lbnd[0]], [$ubnd[0]], [1.0], [1.0], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    my @xin = (-1.0, -0.5, 0.0, 0.5, 1.0);

    my $xout = $cm->Tran1( \@xin, 1 );
    for (my $i = 0; $i < 5; $i ++) {
       delta_ok($xout->[$i], 1.5);
    }

    # One-dimensional ChebyMaps, order 3: 2.5 - 2*x*x
    $cm = new Starlink::AST::ChebyMap(
        1, 1, [@coeffs_1[0 .. 5]], [], [$lbnd[0]], [$ubnd[0]], [1.0], [1.0], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    $xout = $cm->Tran1( \@xin, 1 );
    for (my $i = 0; $i < 5; $i ++) {
       delta_ok($xout->[$i], 2.5 - 2.0 * $xin[$i]**2);
    }

    # One-dimensional ChebyMaps, order 4: 2.5 - 6*x - 2*x*x + 8*x*x*x
    $cm = new Starlink::AST::ChebyMap(
        1, 1, [@coeffs_1[0 .. 8]], [], [$lbnd[0]], [$ubnd[0]], [1.0], [1.0], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    $xout = $cm->Tran1( \@xin, 1 );
    for (my $i = 0; $i < 5; $i ++) {
       delta_ok($xout->[$i], 2.5 - 6.0 * $xin[$i] - 2.0 * $xin[$i]**2 + 8.0 * $xin[$i]**3);
    }

    # One-dimensional ChebyMaps, order 5
    $cm = new Starlink::AST::ChebyMap(
        1, 1,  \@coeffs_1, [], [$lbnd[0]], [$ubnd[0]], [1.0], [1.0], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    $xout = $cm->Tran1( \@xin, 1 );
    for (my $i = 0; $i < 5; $i ++) {
        my @work = (1.0, $xin[$i]);
        for (my $j = 2; $j < 5; $j ++) {
            $work[$j] = 2.0 * $xin[$i] * $work[$j - 1] - $work[$j - 2];
        }

        delta_ok($xout->[$i], 1.5 * $work[0] - 1.0 * $work[2] + 2.0 * $work[3] + 1.3 * $work[4]);
    }

    ok(! $cm->GetL('IterInverse'));

    # The astPolyTran method on a 1-dimensional ChebyMaps, order 2: 1 - 2*x
    $cm = new Starlink::AST::ChebyMap(
        1, 1, \@coeffs_2, [], [$lbnd[0]], [$ubnd[0]], [1.0], [1.0], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    my $cm2 = $cm->PolyTran( 0, 0.01, 0.01, 5, [$lbnd[0]], [$ubnd[0]] );
    isa_ok($cm2, 'Starlink::AST::ChebyMap');

    @xin = (-1.0, -0.5, 0.0, 0.5, 1.0);

    $xout = $cm2->Tran1( \@xin, 1 );
    my $xrec = $cm2->Tran1( $xout, 0 );
    for (my $i = 0; $i < 5; $i ++) {
        # Original tolerance: 1.0e-3 * abs($xin[$i]) is sometimes zero.
        delta_ok($xrec->[$i], $xin[$i]);
    }

    my ($dlbnd, $dubnd) = $cm2->ChebyDomain( 0 );
    delta_ok($dlbnd->[0], -1.0);
    delta_ok($dubnd->[0], 3.0);

    my ($cofs, $nco) = $cm2->PolyCoeffs( 0 );
    is($nco, 1);

    delta_ok($cofs->[0], -1.0);
    delta_ok($cofs->[1], 1.0);
    delta_ok($cofs->[2], 1.0);

    # The astPolyTran method on a 1-dimensional ChebyMaps, order 5.
    @lbnd = (-100.0);
    @ubnd = (100.0);
    $cm = new Starlink::AST::ChebyMap(
        1, 1, \@coeffs_1, [], \@lbnd, \@ubnd, [1.0], [1.0], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');
    $cm2 = $cm->PolyTran( 0, 0.01, 0.01, 10, [-5.0], [50.0] );
    isa_ok($cm2, 'Starlink::AST::ChebyMap');

    @xin = (0.0, 10.0, 20.0, 30.0, 40.0);
    $xout = $cm2->Tran1( \@xin, 1 );
    $xrec = $cm2->Tran1( $xout, 0 );

    for (my $i = 0; $i < 5; $i ++) {
        delta_within($xrec->[$i], $xin[$i], 0.01);
    }

    # ast_equal and ast_copy
    my $cm3 = $cm2->Copy();
    ok($cm2->Equal($cm3));

    # astDump and astLoadChebyMap
    checkdump( $cm2 );

    # Simple 2d ChebyMap.
    # fx(x,y) = T1(x') + T1(y')
    # fy(x,y) = T1(x') - T1(y')

    @lbnd = (-1.0, -1.0);
    @ubnd = (1.0, 1.0);

    $cm = new Starlink::AST::ChebyMap(
        2, 2, \@coeffs_4, [], \@lbnd, \@ubnd, [1.0], [1.0], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    $cm2 = $cm->Copy();
    isa_ok($cm2, 'Starlink::AST::ChebyMap');
    $cm2->Invert();
    $cm3 = Starlink::AST::CmpMap->new( $cm, $cm2, 1, '')->Simplify();
    # Our Simplify() function does not call rebless so can't check via Perl ISA.
    is($cm3->GetC('Class'), 'UnitMap');

    @xin = (0.5, 0.0, -0.5, 0.0);
    my @yin = (0.0, 0.5, 0.0, -0.5);

    ($xout, my $yout) = $cm->Tran2(\@xin, \@yin, 1 );

    for (my $i = 0; $i < 4; $i ++) {
        my $xv = $xin[$i] + $yin[$i];
        my $yv = $xin[$i] - $yin[$i];

        # Original tolerance was 1.0e-6 * abs(xv or yv respectively).
        delta_ok($xout->[$i], $xv);
        delta_ok($yout->[$i], $yv);
    }

    $cm2 = $cm->PolyTran( 0, 0.01, 0.01, 10, \@lbnd, \@ubnd );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    ($xrec, my $yrec) = $cm2->Tran2($xout, $yout, 0);

    for (my $i = 0; $i < 4; $i ++) {
        delta_within($xrec->[$i], $xin[$i], 0.1);
        delta_within($yrec->[$i], $yin[$i], 0.1);
    }
    ($cofs, $nco) = $cm2->PolyCoeffs( 0 );
    is($nco, 4);
    delta_within($cofs, \@coeffs_4, 0.01);

    ($dlbnd, $dubnd) = $cm2->ChebyDomain( 0 );

    delta_ok($dlbnd->[0], -2.0);
    delta_ok($dlbnd->[1], -2.0 );
    delta_ok($dubnd->[0], 2.0 );
    delta_ok($dubnd->[1], 2.0 );

    # 2-dimensional ChebyMaps: forward transformation
    @lbnd = ( 0.0, 0.0 );
    @ubnd = ( 10.0, 10.0 );

    $cm = new Starlink::AST::ChebyMap( 2, 2, \@coeffs_3, [], \@lbnd, \@ubnd, [], [], ' ' );
    isa_ok($cm, 'Starlink::AST::ChebyMap');

    @xin = ( 0.0, 2.0, 6.0, 10.0 );
    @yin = ( 2.0, 5.0, 8.0, 0.0 );

    ($xout, $yout) = $cm->Tran2( \@xin, \@yin, 1 );
    for (my $i = 0; $i < 4; $i ++) {
        my $xi = 2.0*( $xin[$i] - $lbnd[0] )/( $ubnd[0] - $lbnd[0] ) - 1.0;
        my $yi = 2.0*( $yin[$i] - $lbnd[1] )/( $ubnd[1] - $lbnd[1] ) - 1.0;

        my $xv = 1 - 2*$xi*(2*$yi**2 - 1) + $yi;
        my $yv = 1.5 - 2.5*$xi*(2*$yi**2 - 1);

        # Original tolerance 1.0e-6*abs(xv or yv respectively).
        delta_ok($xout->[$i], $xv);
        delta_ok($yout->[$i], $yv);
    }

    # 2-dimensional ChebyMaps: fitted inverse transformation
    my @tlbnd = ( 4.0, 4.0 );
    my @tubnd = ( 6.0, 6.0 );
    $cm2 = $cm->PolyTran( 0, 0.01, 0.01, 10, \@tlbnd, \@tubnd );
    isa_ok($cm2, 'Starlink::AST::ChebyMap');

    @xin = ( 4.0, 4.5, 5.0, 5.5 );
    @yin = ( 6.0, 5.5, 5.0, 4.5 );

    ($xout, $yout) = $cm2->Tran2( \@xin, \@yin, 1 );
    ($xrec, $yrec) = $cm2->Tran2( $xout, $yout, 0 );

    for (my $i = 0; $i < 4; $i ++) {
        delta_within($xrec->[$i], $xin[$i], 0.01);
        delta_within($yrec->[$i], $yin[$i], 0.01);
    }

    # Test recovery of coeffs
    ($cofs, $nco) = $cm2->PolyCoeffs( 1 );
    is($nco, 5);

    delta_ok($cofs, \@coeffs_3);

    ($cofs, $nco) = $cm2->PolyCoeffs( 0 );
    is($nco, 9);

    delta_within( $cofs->[0], 5.0000000000000018, 1.0E-6 );
    delta_within( $cofs->[12], 0.35096188953505458, 1.0E-6 );
    delta_ok( $cofs->[14], 2.0 );

    # Test recovery of domain bounding box
    ($dlbnd, $dubnd) = $cm->ChebyDomain( 1 );

    delta_ok($dlbnd, \@lbnd);
    delta_ok($dubnd, \@ubnd);

    ($dlbnd, $dubnd) = $cm->ChebyDomain( 0 );

    delta_ok($dlbnd->[0], -2.0 );
    delta_ok($dlbnd->[1], -1.0 );
    delta_ok($dubnd->[0], 4.0 );
    delta_ok($dubnd->[1], 4.0 );

    ($dlbnd, $dubnd) = $cm2->ChebyDomain( 1 );

    delta_ok($dlbnd->[0], $lbnd[0] );
    delta_ok($dlbnd->[1], $lbnd[1] );
    delta_ok($dubnd->[0], $ubnd[0] );
    delta_ok($dubnd->[1], $ubnd[1] );

    ($dlbnd, $dubnd) = $cm2->ChebyDomain( 0 );

    delta_within($dlbnd->[0], 0.432, 1.0e-6 );
    delta_within($dlbnd->[1], 1.000816, 1.0e-6 );
    delta_within($dubnd->[0], 1.568, 1.0e-6 );
    delta_within($dubnd->[1], 1.9991836, 1.0e-6 );
};


sub checkdump {
    my $obj = shift;

    my @buff;

    my $ch = new Starlink::AST::Channel( sink => sub {push @buff, $_[0];} );

    is($ch->Write($obj), 1);

    $ch = new Starlink::AST::Channel( source => sub {return shift @buff;} );

    my $result = $ch->Read();
    isa_ok($result, 'Starlink::AST');

    ok($result->Equal($obj));
}
