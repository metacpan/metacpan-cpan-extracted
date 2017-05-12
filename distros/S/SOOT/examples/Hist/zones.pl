use strict;
use warnings;
use SOOT ':all';

$gROOT->Reset();
my $c1 = TCanvas->new('c1','The Ntuple canvas',200,10,700,780);
$gStyle->SetPadBorderMode(0);
$gStyle->SetOptStat(0);
$c1->Divide(2,2,0,0);

my $pad1 = TPad->new('pad1','This is pad1',0.02,0.52,0.48,0.98,21);
my $pad2 = TPad->new('pad2','This is pad2',0.52,0.52,0.98,0.98,21);
my $pad3 = TPad->new('pad3','This is pad3',0.02,0.02,0.48,0.48,21);
my $pad4 = TPad->new('pad4','This is pad4',0.52,0.02,0.98,0.48,1);

$pad1->Draw();
$pad2->Draw();
$pad3->Draw();
$pad4->Draw();

my $h1 = TH2F->new("h1","test1",10,0,1,20,0,20);
my $h2 = TH2F->new("h2","test2",10,0,1,20,0,100);
my $h3 = TH2F->new("h3","test3",10,0,1,20,-1,1);
my $h4 = TH2F->new("h4","test4",10,0,1,20,0,1000);
$h1->FillRandom("gaus", 100000);
$h2->FillRandom("gaus", 100000);
$h3->FillRandom("gaus", 100000);
$h4->FillRandom("gaus", 100000);

$pad1->cd();
$pad1->SetBottomMargin(0);
$pad1->SetRightMargin(0);
$pad1->SetTickx(2);
$h1->Draw();

$pad2->cd();
$pad2->SetLeftMargin(0);
$pad2->SetBottomMargin(0);
$pad2->SetTickx(2);
$pad2->SetTicky(2);
$h2->GetYaxis()->SetLabelOffset(0.01);
$h2->Draw();

$pad3->cd();
$pad3->SetTopMargin(0);
$pad3->SetRightMargin(0);
$h3->Draw();

$pad4->cd();
$pad4->SetLeftMargin(0);
$pad4->SetTopMargin(0);
$pad4->SetTicky(2);
$h4->Draw();

$c1->Update();

$gApplication->Run;

