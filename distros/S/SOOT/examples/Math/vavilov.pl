use strict;
use warnings;
use SOOT ':all';

#test of the TMath::Vavilov distribution
use constant n => 1000;
my $x  = [];
my $y1 = [];
my $y2 = [];
my $y3 = [];
my $y4 = [];

my $r = TRandom->new();
for my $i (0..n-1) {
  my $rv = $r->Uniform(-2, 10);
  push @$x, $rv;
  push @$y1, TMath::Vavilov($x->[$i], 0.30, 0.5);
  push @$y2, TMath::Vavilov($x->[$i], 0.15, 0.5);
  push @$y3, TMath::Vavilov($x->[$i], 0.25, 0.5);
  push @$y4, TMath::Vavilov($x->[$i], 0.05, 0.5);
}

my $c1 = TCanvas->new("c1", "Vavilov density");
$c1->SetGrid();
$c1->SetHighLightColor(19);
my $gr1 = TGraph->new(n, $x, $y1);
my $gr2 = TGraph->new(n, $x, $y2);
my $gr3 = TGraph->new(n, $x, $y3);
my $gr4 = TGraph->new(n, $x, $y4);
$gr1->SetTitle("TMath::Vavilov density");
$gr1->Draw("ap");
$gr2->Draw("psame");
$gr2->SetMarkerColor(kRed);
$gr3->Draw("psame");
$gr3->SetMarkerColor(kBlue);
$gr4->Draw("psame");
$gr4->SetMarkerColor(kGreen);

$gApplication->Run;
