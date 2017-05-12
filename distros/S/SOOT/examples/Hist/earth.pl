use strict;
use warnings;
use SOOT ':all';
use File::Spec;

$gROOT->Reset;
$gStyle->SetPalette(1);
$gStyle->SetOptTitle(1);
$gStyle->SetOptStat(0);

my $c1 = TCanvas->new("c1","earth_projections",1000,800);
$c1->Divide(2,2);

my $h1 = TH2F->new("h1","Aitoff",    180, -180, 180, 179, -89.5, 89.5);
my $h2 = TH2F->new("h2","Mercator",  180, -180, 180, 161, -80.5, 80.5);
my $h3 = TH2F->new("h3","Sinusoidal",180, -180, 180, 181, -90.5, 90.5);
my $h4 = TH2F->new("h4","Parabolic", 180, -180, 180, 181, -90.5, 90.5);

my $inFile = File::Spec->catfile($ENV{ROOTSYS}, qw(share doc root tutorials graphics earth.dat));
open my $fh, "<", $inFile or die "Cannot open $inFile: $!";
while (<$fh>) {
  chomp;
  my ($x, $y) = split /\s+/, $_;
  $x *= 1.;
  $y *= 1.;
  $h1->Fill($x, $y, 1);
  $h2->Fill($x, $y, 1);
  $h3->Fill($x, $y, 1);
  $h4->Fill($x, $y, 1);
}
close $fh;

$c1->cd(1);
$h1->Draw("z aitoff");

$c1->cd(2);
$h2->Draw("z mercator");

$c1->cd(3);
$h3->Draw("z sinusoidal");

$c1->cd(4);
$h4->Draw("z parabolic");

$c1->Update();

$gApplication->Run;

