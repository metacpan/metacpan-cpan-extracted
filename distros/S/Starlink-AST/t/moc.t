#!perl

# This is a Perl conversion of the ast_tester/testmoc.f test program.

use strict;

my ($szmesh1, $szmesh2);

BEGIN {
    $szmesh1 = 868;
    $szmesh2 = 294;
}

use Test::More tests => 42 + $szmesh1 + $szmesh2 + 2 * 2 + 896;
use Test::Number::Delta;

use constant DD2R => 0.017453292519943295769236907684886127134428718885417;

require_ok('Starlink::AST');

do {
    my $mocjson1 = '{"1":[1,2,4], "2":[12,13,14,21,23,25],"8":[]}';
    my $mocjson2 = '{"1":[1,2,4],"2":[12,13,14,21,23,25],"8":[]}';

    my $mocstr1 = '1/1-2,4 2/12-14,21,23,25 8/';
    my $mocstr2 = ' 1/1,2,4   2/12-14, 21,23,25 8/ ';

    my $mxres1 = 824.5167;
    my $mxres2 = 12.883;

    Starlink::AST::Begin();

    my $moc = new Starlink::AST::Moc('maxorder=18,minorder=11');
    isa_ok($moc, 'Starlink::AST::Region');

    is($moc->GetC('System'), 'ICRS', 'System of new MOC');

    my $sf = new Starlink::AST::SkyFrame( 'system=icrs' );

    my @centre = (1.0, 1.0);
    my @point = ( 0.0002 );
    my $reg1 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    $moc->AddRegion( Starlink::AST::Region::AST__OR(), $reg1 );

    delta_within($moc->GetD('MocArea'), 1.485, 1.0e-3, 'MocArea after adding circle');

    datacheck( $moc, 'First datacheck' );

    $moc = new Starlink::AST::Moc( 'maxorder=8,minorder=4' );

    @centre = ( 3.1415927, 0.75 );
    @point = ( 0.5 );
    $reg1 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );

    $moc->AddRegion( Starlink::AST::Region::AST__OR(), $reg1 );

    delta_within($moc->GetD('MaxRes'), $mxres1, 1.0e-4, 'MaxRes after adding circle');

    my ($lbnd, $ubnd) = $moc->GetRegionBounds();

    delta_within($lbnd->[0], 2.4235144, 1.0e-6, 'lbnd[0]');
    delta_within($ubnd->[0], 3.8596708, 1.0e-6, 'ubnd[0]');
    delta_within($lbnd->[1], 0.2499916, 1.0e-6, 'lbnd[1]');
    delta_within($ubnd->[1], 1.2504847, 1.0e-6, 'ubnd[1]');

    my $mesh1 = $moc->GetRegionMesh( 1 );
    is(scalar @$mesh1, $szmesh1 * 2, 'GetRegionMesh npoint');

    for (my $i = 0; $i < $szmesh1; $i ++) {
        my @point = ($mesh1->[$i], $mesh1->[$i + $szmesh1]);
        my $d = $sf->Distance(\@centre, \@point);
        delta_within($d, 0.5, 0.7 * DD2R * $mxres1 / 3600.0, "Distance of point $i");
    }

    is($moc->GetI('moctype'), 4, 'moctype');
    my $ln = $moc->GetI('moclength');
    is($ln, 832, 'moclength');

    my $fc = $moc->GetMocHeader();
    is($fc->GetFitsI('NAXIS1'), 4, 'GetMocHeader NAXIS1');
    is($fc->GetFitsI('NAXIS2'), $ln, 'GetMocHeader NAXIS2');
    is($fc->GetFitsS('TFORM1'), '1J', 'GetMocHeader TFORM1');
    is($fc->GetFitsI('MOCORDER'), 8, 'GetMocHeader MOCORDER');

    datacheck( $moc, 'Second datacheck' );

    my $moc2 = Starlink::AST::_Copy($moc);
    ok(Starlink::AST::Equal($moc, $moc2), 'Copied MOC is equal to original');

    is($moc->Overlap($reg1), 5, 'MOC overlap');

    @centre = (3.1415927, 0.5);
    @point = (0.5);
    $reg1 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    is($moc->Overlap($reg1), 4, 'MOC overlap second circle');

    @centre = (3.1415927, -0.5);
    @point = (0.5);
    $reg1 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    is($moc->Overlap($reg1), 1, 'MOC overlap third circle');

    @centre = (3.1415927, 0.75);
    @point = (0.3);
    $reg1 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    is($moc->Overlap($reg1), 3, 'MOC overlap fourth circle');
    is($reg1->Overlap($moc), 2, 'Fourth circle overlap MOC');

    $moc = new Starlink::AST::Moc( 'maxorder=8,minorder=4' );

    @centre = (0.0, 1.57);
    @point = (0.3);
    $reg1 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    $moc->AddRegion( Starlink::AST::Region::AST__OR(), $reg1 );

    @centre = (0.0, 1.57);
    @point = (0.2);
    my $reg2 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    $reg2->Negate();

    $moc->AddRegion( Starlink::AST::Region::AST__AND(), $reg2 );

    delta_within($moc->GetD('MocArea'), 1.826e6, 0.001e6, 'MocArea after and with negated region');

    $moc2 = new Starlink::AST::Moc( 'maxorder=8,minorder=4' );
    $moc2->AddRegion( Starlink::AST::Region::AST__OR(), $reg1 );

    my $moc3 = new Starlink::AST::Moc( 'maxorder=8,minorder=4' );
    $moc3->AddRegion( Starlink::AST::Region::AST__OR(), $reg2 );

    my $data = $moc3->GetMocData();
    $moc2->AddMocData( Starlink::AST::Region::AST__AND(), 0, -1, $data );

    is($moc->Overlap($moc2), 5, 'Overlap after adding MOC data');
    ok(Starlink::AST::Equal($moc, $moc2), "Equal after adding MOC data");

    my ($dims, $ipdata, $iwcs) = makeimage();

    $moc = new Starlink::AST::Moc( ' ' );
    $moc->AddPixelMaskD( Starlink::AST::Region::AST__OR(), $iwcs, 10.0,
                         Starlink::AST::Polygon::AST__LT(), 0,
                         0.0, $ipdata, $dims );

    is($moc->GetC( 'System' ), 'ICRS', 'MOC from image system');
    delta_within($moc->GetD( 'MaxRes' ), $mxres2, 1.0e-3, 'MOC from image maxres');

    my $mesh2 = $moc->GetRegionMesh( 1 );
    is(scalar @$mesh2, $szmesh2 * 2, 'MOC from image GetRegionMesh npoint');

    @centre = (35.0 * DD2R, 55.0 * DD2R);
    for (my $i = 0; $i < $szmesh2; $i ++) {
        my @point = ($mesh2->[$i], $mesh2->[$i + $szmesh2]);
        my $d = $sf->Distance(\@centre, \@point);
        delta_within($d, 1.745e-3, DD2R * 0.01, "Distance of point $i");
    }

    @centre = (0.0, 1.57);
    @point = (0.3);
    $reg1 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    $moc = new Starlink::AST::Moc( 'maxorder=8,minorder=4' );
    $moc->AddRegion( Starlink::AST::Region::AST__OR(), $reg1 );

    $moc2 = new Starlink::AST::Moc( ' ' );
    $moc2->AddRegion( Starlink::AST::Region::AST__OR(), $moc );

    ok(Starlink::AST::Equal($moc, $moc2), 'OR MOC equal to itself');
    is($moc->Overlap($moc2), 5, 'OR MOC overlap 5 with itself');

    @centre = (0.0, 1.57);
    @point = (0.2);
    $reg2 = new Starlink::AST::Circle( $sf, 1, \@centre, \@point, undef, ' ' );
    $reg2->Negate();
    $moc2 = new Starlink::AST::Moc( 'maxorder=9,minorder=4' );
    $moc2->AddRegion( Starlink::AST::Region::AST__OR(), $reg2 );

    $moc->AddRegion( Starlink::AST::Region::AST__AND(), $moc2 );
    delta_within($moc->GetD( 'MocArea' ), 1.843466e6, 1.0, 'Area after and with negated');

    $moc2 = new Starlink::AST::Moc( 'maxorder=7,minorder=4' );
    $moc2->AddRegion( Starlink::AST::Region::AST__OR(), $reg2 );

    $moc->AddRegion( Starlink::AST::Region::AST__AND(), $moc2 );
    delta_within($moc->GetD( 'MocArea '), 1.803054e6, 1.0, 'Area after second and');

    $moc3 = new Starlink::AST::Moc( ' ' );
    $moc3->SetI( 'MaxOrder', $moc->GetI( 'MaxOrder' ) );

    for (my $i = 0; $i < $moc->GetI('MocLength'); $i ++) {
        my ($order, $npix) = $moc->GetCell($i);

        ok($moc->TestCell($order, $npix, 0), "Test cell $i ($order, $npix)");

        $moc3->AddCell( Starlink::AST::Region::AST__OR(), $order, $npix );
    }

    ok(Starlink::AST::Equal($moc, $moc3), 'MOC equal after adding cells');

    is($moc->Overlap($moc3), 5, 'MOC overlap 5 after adding cells');

    ok(! $moc->TestCell(8, 123456, 0), 'TestCell not in MOC');

    $moc = new Starlink::AST::Moc( ' ' );
    my $json = $moc->AddMocString( Starlink::AST::Region::AST__OR(), 0, -1, $mocstr1 );
    ok(! $json, 'mocstr1 not read as JSON');

    is($moc->GetMocString(0), $mocstr1, 'GetMocString text');

    $moc2 = new Starlink::AST::Moc( ' ' );
    $json = $moc2->AddMocString( Starlink::AST::Region::AST__OR(), 0, -1, $mocstr2 );
    ok(! $json, 'mocstr2 not read as JSON');
    ok(Starlink::AST::Equal($moc, $moc2), 'MOCs from strings equal');
    is($moc->GetI( 'MaxOrder' ), 8, 'MOC from string maxorder');

    $moc = new Starlink::AST::Moc( ' ' );
    $json = $moc->AddMocString( Starlink::AST::Region::AST__OR(), 0, -1, $mocjson1 );
    ok($json, 'mocjson1 read as JSON');

    is($moc->GetMocString(1), $mocjson2, 'GetMocString JSON');
};


sub makeimage {
    my @dims = (100, 100);
    my $ipdata = fillimage( @dims );

    my $fc = new Starlink::AST::FitsChan();
    $fc->SetFitsF( 'CRVAL1', 35.0, ' ', 1 );
    $fc->SetFitsF( 'CRVAL2', 55.0, ' ', 1 );
    $fc->SetFitsF( 'CRPIX1', 50.5, ' ', 1 );
    $fc->SetFitsF( 'CRPIX2', 50.5, ' ', 1 );
    $fc->SetFitsF( 'CDELT1', -0.01, ' ', 1 );
    $fc->SetFitsF( 'CDELT2', 0.01, ' ', 1 );
    $fc->SetFitsS( 'CTYPE1', 'RA---TAN', ' ', 1 );
    $fc->SetFitsS( 'CTYPE2', 'DEC--TAN', ' ', 1 );

    $fc->SetFitsF( 'CRVAL3', -22.9, ' ', 1 );
    $fc->SetFitsF( 'CRPIX3', 1.0, ' ', 1 );
    $fc->SetFitsF( 'CDELT3', 1.27, ' ', 1 );
    $fc->SetFitsS( 'CTYPE3', 'VRAD    ', ' ', 1 );
    $fc->SetFitsS( 'CUNIT3', 'km/s    ', ' ', 1 );

    $fc->Clear( 'Card' );
    my $iwcs = $fc->Read();

    $fc->Annul();

    return ( \@dims, $ipdata, $iwcs );
}


sub fillimage {
    my $nx = shift;
    my $ny = shift;
    my @data;

    # Circular cone with apex (value zero) at image centre, opening upwards.
    my $xc = ( 1.0 + $nx )/2;
    my $yc = ( 1.0 + $ny )/2;

    for (my $j = 0; $j < $ny; $j ++) {
        for (my $i = 0; $i < $nx; $i ++) {
            $data[ $i + $j * $nx ] = sqrt( ($i + 1 - $xc)**2 + ($j + 1 - $yc)**2 );
        }
    }

    return \@data;
}


# Convert the MOC to FITS binary table form, and then convert it back
# to a MOC and compare the before and after MOCs.
sub datacheck {
    my $moc = shift;
    my $text = shift;

    my $data = $moc->GetMocData();

    my $moc2 = new Starlink::AST::Moc( ' ' );

    $moc2->AddMocData(Starlink::AST::Region::AST__OR(), 0, -1, $data);

    is($moc->Overlap($moc2), 5, "$text overlap");

    ok(Starlink::AST::Equal($moc, $moc2), "$text equal");
}
