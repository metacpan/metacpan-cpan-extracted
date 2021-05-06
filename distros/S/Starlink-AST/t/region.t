#!perl

use strict;
use Test::More tests => 39;
use Test::Number::Delta;

require_ok( "Starlink::AST" );

Starlink::AST::Begin();

use constant DD2R => 0.017453292519943295769236907684886127134428718885417;
use constant DAS2R => 4.8481368110953599358991410235794797595635330237270e-6;

# Create reference frame
my $sky = new Starlink::AST::SkyFrame("");


# circle simulating an observation area
my $obsArea = new Starlink::AST::Circle( $sky, 1, [0,0], [1*DAS2R], undef, "" );
isa_ok($obsArea, "Starlink::AST::Region");

my $obsAreaFS = $obsArea->GetRegionFrameSet();
isa_ok($obsAreaFS, 'Starlink::AST::FrameSet');

# Test retrieval of the circle parameters.
do {
    my ($centre, $radius, $p1) = $obsArea->CirclePars();
    delta_ok($centre, [0.0, 0.0]);
    delta_ok($radius, 1.0 * DAS2R);
    is(ref $p1, 'ARRAY');
};

do {
    my ($centre, $radius) = $obsArea->GetRegionDisc();
    delta_ok($centre, [0.0, 0.0]);
    delta_ok($radius, 1.0 * DAS2R);
};

do {
    my $points = $obsArea->GetRegionPoints();
    delta_ok($points->[0], 0.0);
    delta_ok($points->[2], 0.0);
};

# create some "survey fields"

my $circle = new Starlink::AST::Circle( $sky, 1, [0,0], [60*DAS2R], undef, "");
isa_ok($circle, "Starlink::AST::Circle");
my $box = new Starlink::AST::Box($sky, 1,[-0.2,-0.2],[0.4,0.4], undef, "" );
isa_ok($box, "Starlink::AST::Box");
my $int = new Starlink::AST::Interval($sky, [-0.2,-0.2],[0.4,0.4], undef, "" );
isa_ok($int, "Starlink::AST::Interval");
my $ellipse = new Starlink::AST::Ellipse( $sky, 1, [0,0],[120*DAS2R,180*DAS2R],
					  [0], undef, "" );
isa_ok($ellipse, "Starlink::AST::Ellipse");

do {
    my ($centre, $a, $b, $angle, $p1, $p2) = $ellipse->EllipsePars();
    delta_ok($centre, [0.0, 0.0]);
    delta_ok($a, 120.0 * DAS2R);
    delta_ok($b, 180.0 * DAS2R);
    delta_ok($angle, 0.0);
    is(ref $p1, 'ARRAY');
    is(ref $p2, 'ARRAY');
};

my $polygon = new Starlink::AST::Polygon( $sky,
					  [-0.2, 0,0.2,0],
					  [ 0, 0.2, 0, -0.2],
					  undef, "");
isa_ok($polygon, "Starlink::AST::Polygon");

my $downsized = $polygon->Downsize(0.0, 3);
isa_ok($downsized, 'Starlink::AST::Polygon');

# Test for overlap
is( $circle->Overlap( $obsArea ), 3,"Circular area");
is( $box->Overlap( $obsArea ), 3,"Box area");
is( $int->Overlap( $obsArea ), 3,"Interval area");
is( $ellipse->Overlap( $obsArea ), 3,"Ellipse area");
is( $polygon->Overlap( $obsArea ), 3, "Polygonal area" );

# something that doesn't overlap
my $obsArea2 = new Starlink::AST::Circle( $sky, 1, [0,0.5],
					  [1*DAS2R], undef,"");
is( $circle->Overlap( $obsArea2 ), 1,"Outside Circular area");
is( $box->Overlap( $obsArea2 ), 1,"Outside Box area");
is( $int->Overlap( $obsArea2 ), 1,"Outside Interval");
is( $ellipse->Overlap( $obsArea2 ), 1,"Outside Ellipse");

# Test PointInRegion
ok( $int->PointInRegion( [-0.2, 0.4] ), 'Point in region' );
ok( ! $int->PointInRegion( [0.2, -0.4] ), 'Point not in region' );

# Create a compound region

isa_ok( $circle->CmpRegion( $box, Starlink::AST::Region::AST__AND(), "" ),
	"Starlink::AST::CmpRegion" );

# Create a prism.
my $spec = new Starlink::AST::SpecFrame('Unit=Angstrom');
my $int2 = new Starlink::AST::Interval($spec, [5000.0], [6000.0], undef, '');
my $prism = new Starlink::AST::Prism($box, $int2, '');
isa_ok($prism, 'Starlink::AST::Prism');

# Create a point list.
my $pointlist = new Starlink::AST::PointList($sky, [0.0, 0.0], undef, '');
isa_ok($pointlist, 'Starlink::AST::PointList');

# Try SkyOffsetMap.
my $som = $sky->SkyOffsetMap();
isa_ok($som, 'Starlink::AST::Mapping');

# Try manipulating uncertainty information.
my $unc = $obsArea->GetUnc(0);
ok(! defined $unc);

$obsArea->SetUnc(new Starlink::AST::Circle($sky, 1, [0, 0], [0.01 * DAS2R], undef, ''));
my $unc = $obsArea->GetUnc(0);
isa_ok($unc, 'Starlink::AST::Region');
