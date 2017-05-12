use strict;
use warnings;
use SOOT ':all';

# Test the TMath::LaplaceDist and TMath::LaplaceDistI functions
# author: Anna Kreshuk
   
my $c1 = TCanvas->new("c1", "TMath::LaplaceDist",600,800);
$c1->Divide(1, 2);
my $pad1 = $c1->cd(1);
$pad1->SetGrid();
my $flaplace = TF1->new("flaplace", "TMath::LaplaceDist(x, [0], [1])", -10, 10);
$flaplace->SetParameters(0, 1);

my $f1 = $flaplace->DrawCopy();
$f1->SetLineColor(kRed);
$f1->SetLineWidth(1);
$flaplace->SetParameters(0, 2);

my $f2 = $flaplace->DrawCopy("same");
$f2->SetLineColor(kGreen);
$f2->SetLineWidth(1);
$flaplace->SetParameters(2, 1);

my $f3 = $flaplace->DrawCopy("same");
$f3->SetLineColor(kBlue);
$f3->SetLineWidth(1);
$flaplace->SetParameters(2, 2);

my $f4 = $flaplace->DrawCopy("same");
$f4->SetLineColor(kMagenta);
$f4->SetLineWidth(1);

my $legend1 = TLegend->new(.7,.7,.9,.9);
$legend1->AddEntry($f1,"alpha=0 beta=1","l");
$legend1->AddEntry($f2,"alpha=0 beta=2","l");
$legend1->AddEntry($f3,"alpha=2 beta=1","l");
$legend1->AddEntry($f4,"alpha=2 beta=2","l");
$legend1->Draw();

my $pad2 = $c1->cd(2);
$pad2->SetGrid();
my $flaplacei = TF1->new("flaplacei", "TMath::LaplaceDistI(x, [0], [1])", -10, 10);
$flaplacei->SetParameters(0, 1);
my $g1 = $flaplacei->DrawCopy();
$g1->SetLineColor(kRed);
$g1->SetLineWidth(1);
$flaplacei->SetParameters(0, 2);

my $g2 = $flaplacei->DrawCopy("same");
$g2->SetLineColor(kGreen);
$g2->SetLineWidth(1);
$flaplacei->SetParameters(2, 1);

my $g3 = $flaplacei->DrawCopy("same");
$g3->SetLineColor(kBlue);
$g3->SetLineWidth(1);
$flaplacei->SetParameters(2, 2);

my $g4 = $flaplacei->DrawCopy("same");
$g4->SetLineColor(kMagenta);
$g4->SetLineWidth(1);

my $legend2 = TLegend->new(.7,.15,0.9,.35);
$legend2->AddEntry($f1,"alpha=0 beta=1","l");
$legend2->AddEntry($f2,"alpha=0 beta=2","l");
$legend2->AddEntry($f3,"alpha=2 beta=1","l");
$legend2->AddEntry($f4,"alpha=2 beta=2","l");
$legend2->Draw();
$c1->cd();

$gApplication->Run;
