use strict;
use warnings;
use SOOT ':all';

# Example macro describing how to use the different probability
# density functions in ROOT. The macro shows four of them with
# respect to their two variables. In order to run the macro type:
#
#  Author: Andras Zsenei

$gSystem->Load("libMathCore");
my $f1a = TF2->new("f1a","ROOT::Math::cauchy_pdf(x, y)",0,10,0,10);
my $f2a = TF2->new("f2a","ROOT::Math::chisquared_pdf(x,y)",0,20, 0,20);
my $f3a = TF2->new("f3a","ROOT::Math::gaussian_pdf(x,y)",0,10,0,5);
my $f4a = TF2->new("f4a","ROOT::Math::tdistribution_pdf(x,y)",0,10,0,5);

my $c1 = TCanvas->new("c1","c1",1000,750);
$c1->Divide(2,2);

$c1->cd(1);
$f1a->Draw("surf1");
$c1->cd(2);
$f2a->Draw("surf1");
$c1->cd(3);
$f3a->Draw("surf1");
$c1->cd(4);
$f4a->Draw("surf1");

$gApplication->Run;

