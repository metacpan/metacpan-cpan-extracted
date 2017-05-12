use strict;
use SOOT ':all';
use Math::Trig;

#--- Definition of a simple geometry
$gSystem->Load("libGeom");
$gSystem->Load("libGeomBuilder");
$gSystem->Load("libGeomPainter");
SOOT->UpdateClasses();

my $geom = TGeoManager->new("Assemblies", "Geometry using assemblies");

#--- define some materials
my $matVacuum = TGeoMaterial->new("Vacuum", 0,0,0);
my $matAl     = TGeoMaterial->new("Al", 26.98,13,2.7);

#--- define some media
my $Vacuum = TGeoMedium->new("Vacuum",    1, $matVacuum);
my $Al     = TGeoMedium->new("Aluminium", 2, $matAl);

#--- make the top container volume
my $top = $geom->MakeBox("TOP", $Vacuum, 1000., 1000., 100.);
$geom->SetTopVolume($top);

# Make the elementary assembly of the whole structure
my $tplate = TGeoVolumeAssembly->new("TOOTHPLATE"); # FIXME This segfaults!?

my $ntooth = 5;
my $xplate = 25.0;
my $yplate = 50.0;
my $xtooth = 10.0;
my $ytooth = 0.5*$yplate/$ntooth;
my $dshift = 2.*$xplate + $xtooth;

my $plate = $geom->MakeBox("PLATE", $Al, $xplate, $yplate, 1);
$plate->SetLineColor(kBlue);

my $tooth = $geom->MakeBox("TOOTH", $Al, $xtooth, $ytooth, 1);
$tooth->SetLineColor(kBlue);
$tplate->AddNode($plate, 1);

my ($xt, $yt);
for my $i (0..$ntooth)
{
  $xt = $xplate + $xtooth;
  $yt = -$yplate + (4*$i+1)*$ytooth;
  $tplate->AddNode($tooth, $i+1, TGeoTranslation->new($xt,$yt,0)->keep);
  $xt = -$xplate-$xtooth;
  $yt = -$yplate + (4*$i+3)*$ytooth;
  $tplate->AddNode($tooth, $ntooth+$i+1, TGeoTranslation->new($xt,$yt,0)->keep);
}

my $rot1 = TGeoRotation->new();
$rot1->RotateX(90);
my $rot;
my $trans;

# Make a hexagone cell out of 6 toothplates. These can zip togeather
# without generating overlaps (they are self-contained)
my $cell = TGeoVolumeAssembly->new("CELL");
for my $i (0..6) {
  my    $phi = 60.*$i;
  my $phirad = deg2rad($phi);
  my     $xp = $dshift*sin($phirad);
  my     $yp = -$dshift*cos($phirad);
  $rot = TGeoRotation->new($rot1);
  $rot->RotateZ($phi);
  $trans = TGeoCombiTrans->new($xp,$yp,0,$rot);
  $cell->AddNode($tplate, $i+1, $trans); # FIXME SEGV here
}

# Make a row as an assembly of cells, then combine rows in a honeycomb
# structure. This again works without any need to define rows as "overlapping"
my $row = TGeoVolumeAssembly->new("ROW");
my $ncells = 5;
for my $i (0..$ncells-1) {
  my $ycell = (2*$i+1)*($dshift+10);
  $row->AddNode($cell, $ncells+$i+1, TGeoTranslation->new(0,$ycell,0)->keep);
  $row->AddNode($cell, $ncells-$i,   TGeoTranslation->new(0,-$ycell,0)->keep);
}

my $dxrow = 3.*($dshift+10.)*tan(deg2rad(30.0));
my $dyrow = $dshift+10.;
my $nrows = 5;
for my $i (0..$nrows)
{
  my $xrow = 0.5*(2*$i+1)*$dxrow;
  my $yrow = 0.5*$dyrow;
  if (($i%2)==0) {
    $yrow = -$yrow;
  }
  $top->AddNode($row, $nrows+$i+1, TGeoTranslation->new($xrow,$yrow,0)->keep);
  $top->AddNode($row, $nrows-$i,    TGeoTranslation->new(-$xrow,-$yrow,0)->keep);
}

#--- close the geometry
$geom->CloseGeometry();

$geom->SetVisLevel(4);
$geom->SetVisOption(0);
$top->Draw();

$gApplication->Run;
