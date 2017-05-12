use strict;
use warnings;
use SOOT ':all';

# Setting alphanumeric labels in a 1-d histogram
# author; Rene Brun
my $people = [qw(
  Jean Pierre Marie Odile Sebastien Fons Rene
  Nicolas Xavier Greg Bjarne Anton Otto Eddy Peter Pasha
  Philippe Suzanne Jeff Valery
)];
my $size = scalar @$people;

my $c1 = TCanvas->new("c1","demo bin labels",10,10,900,500);
$c1->SetGrid();
$c1->SetBottomMargin(0.15);
my $h = TH1F->new("h","test",$size,0,$size);
$h->SetFillColor(38);
$h->Fill($gRandom->Gaus(0.5*$size,0.2*$size)*1.0) for 0..4999;
$h->SetStats(0);
$h->GetXaxis()->SetBinLabel($_,$people->[$_-1]) for 1..$size-1;
$h->Draw();
my $pt = TPaveText->new(0.6,0.7,0.98,0.98,"brNDC");
$pt->SetFillColor(18);
$pt->SetTextAlign(12);
$pt->AddText("Use the axis Context Menu LabelsOption");
$pt->AddText(" \"a\"   to sort by alphabetic order");
$pt->AddText(" \">\"   to sort by decreasing vakues");
$pt->AddText(" \"<\"   to sort by increasing vakues");
$pt->Draw();

$gApplication->Run;

