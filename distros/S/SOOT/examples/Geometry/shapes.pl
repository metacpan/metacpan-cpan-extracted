use strict;
use warnings;
use SOOT ':all';

$gSystem->Load("libGeom");
$gSystem->Load("libGeomBuilder");
$gSystem->Load("libGeomPainter");
SOOT->UpdateClasses();

$gROOT->Reset();
my $c1 = TCanvas->new('c1', 'Geometry Shapes', 200, 10, 700, 500);

#  Define some volumes
my $brik = TBRIK->new('BRIK', 'BRIK', 'void', 200, 150, 150);
my $trd1 = TTRD1->new('TRD1', 'TRD1', 'void', 200, 50, 100, 100);
my $trd2 = TTRD2->new('TRD2', 'TRD2', 'void', 200, 50, 200, 50, 100);
my $trap = TTRAP->new('TRAP', 'TRAP', 'void', 190, 0, 0, 60, 40, 90, 15, 120, 80, 180, 15);
my $para = TPARA->new('PARA', 'PARA', 'void', 100, 200, 200, 15, 30, 30);
my $gtra = TGTRA->new('GTRA', 'GTRA', 'void', 390, 0, 0, 20, 60, 40, 90, 15, 120, 80, 180, 15);
my $tube = TTUBE->new('TUBE', 'TUBE', 'void', 150, 200, 400);
my $tubs = TTUBS->new('TUBS', 'TUBS', 'void', 80, 100, 100, 90, 235);
my $cone = TCONE->new('CONE', 'CONE', 'void', 100, 50, 70, 120, 150);
my $cons = TCONS->new('CONS', 'CONS', 'void', 50, 100, 100, 200, 300, 90, 270);
my $sphe  = TSPHE->new('SPHE',  'SPHE',  'void', 25, 340, 45, 135,  0, 270);
my $sphe1 = TSPHE->new('SPHE1', 'SPHE1', 'void',  0, 140,  0, 180,  0, 360);
my $sphe2 = TSPHE->new('SPHE2', 'SPHE2', 'void',  0, 200, 10, 120, 45, 145);

my $pcon = TPCON->new('PCON', 'PCON', 'void', 180, 270, 4);
$pcon->DefineSection(0, -200, 50, 100);
$pcon->DefineSection(1,  -50, 50,  80);
$pcon->DefineSection(2,   50, 50,  80);
$pcon->DefineSection(3,  200, 50, 100);

my $pgon = TPGON->new('PGON', 'PGON', 'void', 180, 270, 8, 4);
$pgon->DefineSection(0, -200, 50, 100);
$pgon->DefineSection(1,  -50, 50,  80);
$pgon->DefineSection(2,   50, 50,  80);
$pgon->DefineSection(3,  200, 50, 100);

#  Set shapes attributes
$brik->SetLineColor(1);
$trd1->SetLineColor(2);
$trd2->SetLineColor(3);
$trap->SetLineColor(4);
$para->SetLineColor(5);
$gtra->SetLineColor(7);
$tube->SetLineColor(6);
$tubs->SetLineColor(7);
$cone->SetLineColor(2);
$cons->SetLineColor(3);
$pcon->SetLineColor(6);
$pgon->SetLineColor(2);
$sphe->SetLineColor(1);
$sphe1->SetLineColor(2);
$sphe2->SetLineColor(4);

#  Build the geometry hierarchy
my $node1 = TNode->new('NODE1', 'NODE1', 'BRIK');
$node1->cd();

my $node2  = TNode->new( 'NODE2',  'NODE2', 'TRD1',     0,     0, -1000);
my $node3  = TNode->new( 'NODE3',  'NODE3', 'TRD2',     0,     0,  1000);
my $node4  = TNode->new( 'NODE4',  'NODE4', 'TRAP',     0, -1000,     0);
my $node5  = TNode->new( 'NODE5',  'NODE5', 'PARA',     0,  1000,     0);
my $node6  = TNode->new( 'NODE6',  'NODE6', 'TUBE', -1000,     0,     0);
my $node7  = TNode->new( 'NODE7',  'NODE7', 'TUBS',  1000,     0,     0);
my $node8  = TNode->new( 'NODE8',  'NODE8', 'CONE',  -300,  -300,     0);
my $node9  = TNode->new( 'NODE9',  'NODE9', 'CONS',   300,   300,     0);
my $node10 = TNode->new('NODE10', 'NODE10', 'PCON',     0, -1000, -1000);
my $node11 = TNode->new('NODE11', 'NODE11', 'PGON',     0,  1000,  1000);
my $node12 = TNode->new('NODE12', 'NODE12', 'GTRA',     0,  -400,   700);
my $node13 = TNode->new('NODE13', 'NODE13', 'SPHE',    10,  -400,   500);
my $node14 = TNode->new('NODE14', 'NODE14', 'SPHE1',   10,   250,   300);
my $node15 = TNode->new('NODE15', 'NODE15', 'SPHE2',   10,  -100,  -200);

# Draw this geometry in the current canvas
$node1->cd();
$node1->Draw();
$c1->Update();

$c1->GetViewer3D;

$gApplication->Run;

