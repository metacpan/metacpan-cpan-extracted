use strict;
use warnings;
use SOOT ':all';

$gROOT->Reset();
my $c1 = TCanvas->new("c1");
$c1->Range(0,0,1,1);
my $par = TPaveLabel->new(0.1,0.8,0.9,0.95,"Examples of various arrow formats");
$par->SetFillColor(42);
$par->Draw();

my $ar1 = TArrow->new(0.1,0.1,0.1,0.7);
$ar1->Draw();

my $ar2 = TArrow->new(0.2,0.1,0.2,0.7,0.05,"|>");
$ar2->SetAngle(40);
$ar2->SetLineWidth(2);
$ar2->Draw();

my $ar3 = TArrow->new(0.3,0.1,0.3,0.7,0.05,"<|>");
$ar3->SetAngle(40);
$ar3->SetLineWidth(2);
$ar3->Draw();

my $ar4 = TArrow->new(0.46,0.7,0.82,0.42,0.07,"|>");
$ar4->SetAngle(60);
$ar4->SetLineWidth(2);
$ar4->SetFillColor(2);
$ar4->Draw();

my $ar5 = TArrow->new(0.4,0.25,0.95,0.25,0.15,"<|>");
$ar5->SetAngle(60);
$ar5->SetLineWidth(4);
$ar5->SetLineColor(4);
$ar5->SetFillStyle(3008);
$ar5->SetFillColor(2);
$ar5->Draw();

$gApplication->Run;
