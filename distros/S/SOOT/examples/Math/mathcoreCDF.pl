use strict;
use SOOT ':all';

# Example macro describing how to use the different cumulative
# distribution functions in ROOT. The macro shows four of them with
# respect to their two variables. In order to run the macro type:

# FIXME doesn't work... didn't work in CINT either. Need to figure out MathCore better

$gSystem->Load("root/libMathCore");
my $f1a = TF2->new("f1a", "ROOT::Math::breitwigner_prob(x, y)", -10, 10, 0, 10);
my $f2a = TF2->new("f2a", "ROOT::Math::cauchy_quant(x,y)", 0, 20, 0,20);
my $f3a = TF2->new("f3a", "ROOT::Math::normal_quant(x,y)", -10, 10, 0, 5);
my $f4a = TF2->new("f4a", "ROOT::Math::exponential_prob(x,y)", 0, 10, 0, 5);

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

$c1->Update;

$gApplication->Run;
