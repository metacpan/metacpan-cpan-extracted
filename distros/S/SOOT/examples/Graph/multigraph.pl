use strict;
use warnings;
use SOOT ':all';

$gROOT->Reset;
$gStyle->SetOptFit;
my $c1 = TCanvas->new("c1","multigraph",200,10,700,500);
$c1->SetGrid();

# draw a frame to define the range
my $mg = TMultiGraph->new();

# create first graph
my $n1 = 10;
my $x1  = [-0.1, 0.05, 0.25, 0.35, 0.5, 0.61,0.7,0.85,0.89,0.95];
my $y1  = [-1.,2.9,5.6,7.4,9,9.6,8.7,6.3,4.5,1];
my $ex1 = [.05,.1,.07,.07,.04,.05,.06,.07,.08,.05];
my $ey1 = [.8,.7,.6,.5,.4,.4,.5,.6,.7,.8];
my $gr1 = TGraphErrors->new($n1,$x1,$y1,$ex1,$ey1);
$gr1->SetMarkerColor(kBlue);
$gr1->SetMarkerStyle(21);
$gr1->Fit("pol6","q");
$mg->Add($gr1);

# create second graph
my $n2 = 10;
my $x2  = [-0.28, 0.005, 0.19, 0.29, 0.45, 0.56,0.65,0.80,0.90,1.01];
my $y2  = [2.1,3.86,7,9,10,10.55,9.64,7.26,5.42,2];
my $ex2 = [.04,.12,.08,.06,.05,.04,.07,.06,.08,.04];
my $ey2 = [.6,.8,.7,.4,.3,.3,.4,.5,.6,.7];
my $gr2 = TGraphErrors->new($n2,$x2,$y2,$ex2,$ey2);
$gr2->SetMarkerColor(kRed);
$gr2->SetMarkerStyle(20);
$gr2->Fit("pol5","q");

$mg->Add($gr2);

$mg->Draw("ap");

 #force drawing of canvas to generate the fit TPaveStats
$c1->Update();
my $stats1 = $gr1->GetListOfFunctions()->FindObject("stats");
my $stats2 = $gr2->GetListOfFunctions()->FindObject("stats");
$stats1->SetTextColor(kBlue); 
$stats2->SetTextColor(kRed); 
$stats1->SetX1NDC(0.12); $stats1->SetX2NDC(0.32); $stats1->SetY1NDC(0.75);
$stats2->SetX1NDC(0.72); $stats2->SetX2NDC(0.92); $stats2->SetY1NDC(0.78);
$c1->Modified();

$gApplication->Run;
