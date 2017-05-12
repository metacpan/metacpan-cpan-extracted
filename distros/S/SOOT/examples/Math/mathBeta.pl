use strict;
use warnings;
use SOOT ':all';

my $c1 = TCanvas->new("c1", "TMath::BetaDist",600,800);
$c1->Divide(1, 2);
my $pad1 = $c1->cd(1);
$pad1->SetGrid();
my $fbeta = TF1->new("fbeta", "TMath::BetaDist(x, [0], [1])", 0, 1);
$fbeta->SetParameters(0.5, 0.5);
my $f1 = $fbeta->DrawCopy();
$f1->SetLineColor(kRed);
$f1->SetLineWidth(1);
$fbeta->SetParameters(0.5, 2);
my $f2 = $fbeta->DrawCopy("same");
$f2->SetLineColor(kGreen);
$f2->SetLineWidth(1);
$fbeta->SetParameters(2, 0.5);
my $f3 = $fbeta->DrawCopy("same");
$f3->SetLineColor(kBlue);
$f3->SetLineWidth(1);
$fbeta->SetParameters(2, 2);
my $f4 = $fbeta->DrawCopy("same");
$f4->SetLineColor(kMagenta);
$f4->SetLineWidth(1);
my $legend1 = TLegend->new(.5,.7,.8,.9);
$legend1->AddEntry($f1,"p=0.5  q=0.5","l");
$legend1->AddEntry($f2,"p=0.5  q=2","l");
$legend1->AddEntry($f3,"p=2    q=0.5","l");
$legend1->AddEntry($f4,"p=2    q=2","l");
$legend1->Draw();

my $pad2 = $c1->cd(2);
$pad2->SetGrid();
my $fbetai = TF1->new("fbetai", "TMath::BetaDistI(x, [0], [1])", 0, 1);
$fbetai->SetParameters(0.5, 0.5);
my $g1=$fbetai->DrawCopy();
$g1->SetLineColor(kRed);
$g1->SetLineWidth(1);
$fbetai->SetParameters(0.5, 2);
my $g2 = $fbetai->DrawCopy("same");
$g2->SetLineColor(kGreen);
$g2->SetLineWidth(1);
$fbetai->SetParameters(2, 0.5);
my $g3 = $fbetai->DrawCopy("same");
$g3->SetLineColor(kBlue);
$g3->SetLineWidth(1);
$fbetai->SetParameters(2, 2);
my $g4 = $fbetai->DrawCopy("same");
$g4->SetLineColor(kMagenta);
$g4->SetLineWidth(1);

my $legend2 = TLegend->new(.7,.15,0.9,.35);
$legend2->AddEntry($f1,"p=0.5  q=0.5","l");
$legend2->AddEntry($f2,"p=0.5  q=2","l");
$legend2->AddEntry($f3,"p=2    q=0.5","l");
$legend2->AddEntry($f4,"p=2    q=2","l");
$legend2->Draw();
$c1->cd();
$c1->Update();


$gApplication->Run;

