use strict;
use warnings;
use SOOT ':all';

use constant NQ => 100;
use constant NSHOTS => 10;

# demo for quantiles
# Author; Rene Brun
my $xq = [map {$_/NQ} 1..NQ]; # position where to compute the quantiles in [0,1]
my $yq = [(0.) x NQ]; # array to contain the quantiles

my $gr70 = TGraph->new(NSHOTS);
my $gr90 = TGraph->new(NSHOTS);
my $gr98 = TGraph->new(NSHOTS);
my $h = TH1F->new("h", "demo quantiles", 50, -3, 3);

for my $shot (0..NSHOTS-1) {
  $h->FillRandom("gaus", 50);
  $h->GetQuantiles(NQ, $yq, $xq);
  $gr70->SetPoint($shot, $shot+1, $yq->[70]*1.0);
  $gr90->SetPoint($shot, $shot+1, $yq->[90]*1.0);
  $gr98->SetPoint($shot, $shot+1, $yq->[98]*1.0);
}

# show the original histogram in the top pad
my $c1 = TCanvas->new("c1", "demo quantiles", 10, 10, 600, 900);
$c1->SetFillColor(41);
$c1->Divide(1, 3);
$c1->cd(1);
$h->SetFillColor(38);
$h->Draw();

# show the final quantiles in the middle pad
$c1->cd(2);
$gPad->SetFrameFillColor(33);
$gPad->SetGrid();
my $gr = TGraph->new(NQ, $xq, $yq);
$gr->SetTitle("final quantiles");
$gr->SetMarkerStyle(21);
$gr->SetMarkerColor(kRed);
$gr->SetMarkerSize(0.3);
$gr->Draw("ap");

# show the evolution of some  quantiles in the bottom pad
$c1->cd(3);
$gPad->SetFrameFillColor(17);
$gPad->DrawFrame(0, 0, NSHOTS+1, 3.2);
$gPad->SetGrid();
$gr98->SetMarkerStyle(22);
$gr98->SetMarkerColor(kRed);
$gr98->Draw("lp");
$gr90->SetMarkerStyle(21);
$gr90->SetMarkerColor(kBlue);
$gr90->Draw("lp");
$gr70->SetMarkerStyle(20);
$gr70->SetMarkerColor(kMagenta);
$gr70->Draw("lp");

# add a legend
my $legend = TLegend->new(0.85, 0.74, 0.95, 0.95);
$legend->SetTextFont(72);
$legend->SetTextSize(0.05);
$legend->AddEntry($gr98," q98","lp");
$legend->AddEntry($gr90," q90","lp");
$legend->AddEntry($gr70," q70","lp");
$legend->Draw();

$gApplication->Run;
