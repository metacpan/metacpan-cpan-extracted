use strict;
use warnings;
use SOOT ':all';

# example of macro illustrating how to superimpose two histograms
# with different scales in the "same" pad.

my $c1 = TCanvas->new("c1","example of two overlapping pads",600,400);

# create/fill draw h1
$gStyle->SetOptStat(0);

my $h1 = TH1D->new("h1","my histogram",100,-3,3);
$h1->FillRandom('gaus', 10000);
$h1->Draw();
$c1->Update();

# create hint1 filled with the bins integral of h1
my $hint1 = TH1F->new("hint1","h1 bins integral",100,-3,3);
my $sum = 0;
for my $i (1..100) {
  $sum += $h1->GetBinContent($i);
  $hint1->SetBinContent($i, $sum);
}

# scale hint1 to the pad coordinates
my $rightmax = 1.1*$hint1->GetMaximum();
my $scale = $c1->GetUymax()/$rightmax;

$hint1->SetLineColor(kRed);
$hint1->Scale($scale);
$hint1->Draw("same");

# draw an axis on the right side
my $axis = TGaxis->new($c1->GetUxmax()*1.0, $c1->GetUymin()*1.0,
                            $c1->GetUxmax()*1.0, $c1->GetUymax()*1.0, 
                            0,$rightmax,510,"+L");
$axis->SetLineColor(kRed);
$axis->SetTextColor(kRed);
$axis->Draw();

$c1->Update;

$gApplication->Run;

