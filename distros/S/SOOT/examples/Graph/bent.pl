use strict;
use warnings;
use SOOT ':all';

$gROOT->Reset();

my $n = 10;
my $x    = [-0.22, 0.05, 0.25, 0.35, 0.5, 0.61,0.7,0.85,0.89,0.95];
my $y    = [1.,2.9,5.6,7.4,9,9.6,8.7,6.3,4.5,1];
my $exl  = [.05,.1,.07,.07,.04,.05,.06,.07,.08,.05];
my $eyl  = [.8,.7,.6,.5,.4,.4,.5,.6,.7,.8];
my $exh  = [.02,.08,.05,.05,.03,.03,.04,.05,.06,.03];
my $eyh  = [.6,.5,.4,.3,.2,.2,.3,.4,.5,.6];
my $exld = [.0,.0,.0,.0,.0,.0,.0,.0,.0,.0];
my $eyld = [.0,.0,.05,.0,.0,.0,.0,.0,.0,.0];
my $exhd = [.0,.0,.0,.0,.0,.0,.0,.0,.0,.0];
my $eyhd = [.0,.0,.0,.0,.0,.0,.0,.0,.05,.0];
my $gr = TGraphBentErrors->new($n,$x,$y,$exl,$exh,$eyl,$eyh,$exld,$exhd,$eyld,$eyhd);
$gr->SetTitle("TGraphBentErrors Example");
$gr->SetMarkerColor(4);
$gr->SetMarkerStyle(21);
$gr->Draw("ALP");
$gApplication->Run;

