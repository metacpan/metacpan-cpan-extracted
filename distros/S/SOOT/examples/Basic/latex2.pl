use strict;
use warnings;
use SOOT ':all';

$gROOT->Reset();
my $c1 = TCanvas->new("c1");
my $l =  TLatex->new;
$l->SetTextAlign(23);
$l->SetTextSize(0.1);
$l->DrawLatex(0.5,0.95,"e^{+}e^{-}#rightarrowZ^{0}#rightarrowI#bar{I}, q#bar{q}");
$l->DrawLatex(0.5,0.75,"|#vec{a}#bullet#vec{b}|=#Sigmaa^{i}_{jk}+b^{bj}_{i}");
$l->DrawLatex(0.5,0.5,"i(#partial_{#mu}#bar{#psi}#gamma^{#mu}+m#bar{#psi})=0#Leftrightarrow(#Box+m^{2})#psi=0");
$l->DrawLatex(0.5,0.3,"L_{em}=eJ^{#mu}_{em}A_{#mu} , J^{#mu}_{em}=#bar{I}#gamma_{#mu}I , M^{j}_{i}=#SigmaA_{#alpha}#tau^{#alphaj}_{i}");
$c1->Print("latex2.ps");

$gApplication->Run;

__END__
