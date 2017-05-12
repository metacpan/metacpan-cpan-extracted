use strict;
use warnings;
use SOOT ':all';
use Math::Trig; 

$gSystem->Load("libGeom");
$gSystem->Load("libGeomBuilder");
$gSystem->Load("libGeomPainter");
SOOT->UpdateClasses();

# use TGeo classes to draw a model of a nucleus
# 
# Author: Otto Schaile
my $nProtons  = shift || 40;
my $nNeutrons = shift || 60;

my $NeutronRadius = 60;
my $ProtonRadius = 60;
my $NucleusRadius;
my $distance = 60;

my $vol = $nProtons + $nNeutrons;
$vol = 3 * $vol / (4 * pi);

$NucleusRadius = $distance * $vol**(1./3.);

my $geom = TGeoManager->new("nucleus", "Model of a nucleus");
$geom->SetNsegments(40);
my $matEmptySpace = TGeoMaterial->new("EmptySpace", 0, 0, 0);
my $matProton     = TGeoMaterial->new("Proton"    , .938, 1., 10000.);
my $matNeutron    = TGeoMaterial->new("Neutron"   , .935, 0., 10000.);

my $EmptySpace = TGeoMedium->new("Empty", 1, $matEmptySpace);
my $Proton     = TGeoMedium->new("Proton", 1, $matProton);
my $Neutron    = TGeoMedium->new("Neutron",1, $matNeutron);

#  the space where the nucleus lives (top container volume)

my $worldx = 200.;
my $worldy = 200.;
my $worldz = 200.;

my $top = $geom->MakeBox("WORLD", $EmptySpace, $worldx, $worldy, $worldz); 
$geom->SetTopVolume($top);

my $proton  = $geom->MakeSphere("proton",  $Proton,  0., $ProtonRadius); 
my $neutron = $geom->MakeSphere("neutron", $Neutron, 0., $NeutronRadius); 
$proton->SetLineColor(kRed);
$neutron->SetLineColor(kBlue);

my ($x, $y, $z); 
my $i = 0; 
while ($i < $nProtons) {
  $x = $gRandom->Gaus(0.0, 1.0);
  $y = $gRandom->Gaus(0.0, 1.0);
  $z = $gRandom->Gaus(0.0, 1.0);
  printf "%f %f %f\n", $x, $y, $z;
  if (sqrt($x**2 + $y**2 + $z**2) < 1) {
     $x = (2 * $x - 1) * $NucleusRadius;
     $y = (2 * $y - 1) * $NucleusRadius;
     $z = (2 * $z - 1) * $NucleusRadius;
     my $trans = TGeoTranslation->new($x*1.0, $y*1.0, $z*1.0)->keep;
     $top->AddNode($proton, $i, $trans);
     $i++;
  }
}
$i = 0; 
while ($i < $nNeutrons) {
  $x = $gRandom->Gaus(0.0, 1.0);
  $y = $gRandom->Gaus(0.0, 1.0);
  $z = $gRandom->Gaus(0.0, 1.0);
  if (sqrt($x**2 + $y**2 + $z**2) < 1) {
     $x = (2 * $x - 1) * $NucleusRadius;
     $y = (2 * $y - 1) * $NucleusRadius;
     $z = (2 * $z - 1) * $NucleusRadius;
     my $trans = TGeoTranslation->new($x*1.0, $y*1.0, $z*1.0)->keep;
     $top->AddNode($neutron, $i + $nProtons, $trans);
     $i++;
  }
}
$geom->CloseGeometry();
$geom->SetVisLevel(4);
$top->Draw("ogl");

$gApplication->Run;
