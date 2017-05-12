use strict;
use warnings;
use SOOT ':all';

my $npoints = 3;
my $xaxis  = [1.,2.,3.];
my $yaxis  = [10.,20.,30.];
my $errorx = [0.5,0.5,0.5];
my $errory = [5.,5.,5.];
my $exl    = [0.5,0.5,0.5];
my $exh    = [0.5,0.5,0.5];
my $eyl    = [5.,5.,5.];
my $eyh    = [5.,5.,5.];

my $gr1 = TGraph->new($npoints,$xaxis,$yaxis);
my $gr2 = TGraphErrors->new($npoints,$xaxis,$yaxis,$errorx,$errory);
my $gr3 = TGraphAsymmErrors->new($npoints,$xaxis,$yaxis,$exl,$exh,$eyl,$eyh);
my $ff  = TF2->new("ff","-1./y");

my $c1 = TCanvas->new("c1","c1");
$c1->Divide(2,3);
# TGraph
$c1->cd(1);
$gr1->DrawClone("A*");
$c1->cd(2);
$gr1->Apply($ff);
$gr1->Draw("A*");

# TGraphErrors
$c1->cd(3);
$gr2->DrawClone("A*");
$c1->cd(4);
$gr2->Apply($ff);
$gr2->Draw("A*");

# TGraphAsymmErrors
$c1->cd(5);
$gr3->DrawClone("A*");
$c1->cd(6);
$gr3->Apply($ff);
$gr3->Draw("A*");

$c1->Update;

$gApplication->Run;

