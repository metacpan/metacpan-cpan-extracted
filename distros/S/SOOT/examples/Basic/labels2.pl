use strict;
use warnings;
use SOOT ':all';

use constant nx => 12;
use constant ny => 20;
my $months  = [qw(January February March April May June July
                  August September October November December)];
my $people  = [qw(Jean Pierre Marie Odile Sebastien Fons Rene
                  Nicolas Xavier Greg Bjarne Anton Otto Eddy Peter Pasha
                  Philippe Suzanne Jeff Valery)];
my $c1 = TCanvas->new("c1","demo bin labels",10,10,800,800);
$c1->SetGrid();
$c1->SetLeftMargin(0.15);
$c1->SetBottomMargin(0.15);
my $h = TH2F->new("h","test",nx,0,nx,ny,0,ny);
$h->Fill($gRandom->Gaus(0.5*nx,0.2*nx)*1.0, $gRandom->Gaus(0.5*ny,0.2*ny)*1.0) for 0..4999;

$h->SetStats(0);
$h->GetXaxis()->SetBinLabel($_,$months->[$_-1]) for 1..nx-1;
$h->GetYaxis()->SetBinLabel($_,$people->[$_-1]) for 1..ny-1; 
$h->Draw("text");

my $pt = TPaveText->new(0.6,0.85,0.98,0.98,"brNDC");
$pt->SetFillColor(18);
$pt->SetTextAlign(12);
$pt->AddText("Use the axis Context Menu LabelsOption");
$pt->AddText(" \"a\"   to sort by alphabetic order");
$pt->AddText(" \">\"   to sort by decreasing values");
$pt->AddText(" \"<\"   to sort by increasing values");
$pt->Draw();

$c1->Update();

$gApplication->Run;
