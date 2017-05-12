use strict;
use warnings;
use Math::Trig;
use SOOT ':all';

my $c1 = TCanvas->new("c1", "A canvas", 10,10, 600, 300);
$c1->Range(0, 0, 140, 60);
my $linsav = int($gStyle->GetLineWidth());

$gStyle->SetLineWidth(3);

my $t = TLatex->new();
$t->SetTextAlign(22);
$t->SetTextSize(0.1);

my $l;
$l = TLine->new(10, 10, 30, 30); 
$l->Draw();

$l = TLine->new(10, 50, 30, 30); 
$l->Draw();

my $ginit = TCurlyArc->new(30, 30, 12.5*sqrt(2), 135, 225);
$ginit->SetWavy();
$ginit->Draw();

$t->DrawLatex(7,6,"e^{-}");
$t->DrawLatex(7,55,"e^{+}");
$t->DrawLatex(7,30,"#gamma");

my $gamma = TCurlyLine->new(30, 30, 55, 30);
$gamma->SetWavy();
$gamma->Draw();
$t->DrawLatex(42.5,37.7,"#gamma");

my $a = TArc->new(70, 30, 15);
$a->Draw();
$t->DrawLatex(55, 45,"#bar{q}");
$t->DrawLatex(85, 15,"q");

my $gluon = TCurlyLine->new(70, 45, 70, 15);
$gluon->Draw();
$t->DrawLatex(77.5,30,"g");

my $z0 = TCurlyLine->new(85, 30, 110, 30);
$z0->SetWavy();
$z0->Draw();
$t->DrawLatex(100, 37.5,"Z^{0}");

$l = TLine->new(110, 30, 130, 10); 
$l->Draw();

$l = TLine->new(110, 30, 130, 50); 
$l->Draw();

my $gluon1 = TCurlyArc->new(110, 30, 12.5*sqrt(2), 315, 45);
$gluon1->Draw();

$t->DrawLatex(135,6,"#bar{q}");
$t->DrawLatex(135,55,"q");
$t->DrawLatex(135,30,"g");
$c1->Update();

$gStyle->SetLineWidth($linsav);
$gApplication->Run;

