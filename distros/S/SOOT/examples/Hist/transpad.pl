use strict;
use warnings;
use SOOT ':all';

# Example of a canvas showing two histograms with different scales.
# The second histogram is drawn in a transparent pad
my $c1 = TCanvas->new("c1","transparent pad",200,10,700,500);
my $pad1 = TPad->new("pad1","",0,0,1,1);
my $pad2 = TPad->new("pad2","",0,0,1,1);
$pad2->SetFillStyle(4000); # will be transparent
$pad1->Draw();
$pad1->cd();

my $h1 = TH1F->new("h1","h1",100,-3,3);
my $h2 = TH1F->new("h2","h2",100,-3,3);
my $r = TRandom->new;

my $nloop = 100000;
for my $i (0..$nloop-1) {
  if ($i < 1000) {
    my $x1 = $r->Gaus(-1,0.5);
    $h1->Fill($x1);
  }
  my $x2 = $r->Gaus(1,1.5);
  $h2->Fill($x2);
}

$h1->Draw();
$pad1->Update(); #this will force the generation of the "stats" box
my $ps1 = $h1->GetListOfFunctions()->FindObject("stats");
$ps1->SetX1NDC(0.4); 
$ps1->SetX2NDC(0.6);
$pad1->Modified();
$c1->cd();
 
#compute the pad range with suitable margins
my $ymin = 0;
my $ymax = 2000;
my $dy = ($ymax-$ymin)/0.8; # 10 per cent margins top and bottom
my $xmin = -3;
my $xmax = 3;
my $dx = ($xmax-$xmin)/0.8; # 10 per cent margins left and right
$pad2->Range($xmin-0.1*$dx,$ymin-0.1*$dy,$xmax+0.1*$dx,$ymax+0.1*$dy);
$pad2->Draw();
$pad2->cd();
$h2->SetLineColor(kRed);
$h2->Draw("sames");
$pad2->Update();

my $ps2 = $h2->GetListOfFunctions()->FindObject("stats");
$ps2->SetX1NDC(0.65); 
$ps2->SetX2NDC(0.85);
$ps2->SetTextColor(kRed);

# draw axis on the right side of the pad
my $axis = TGaxis->new($xmax,$ymin,$xmax,$ymax,$ymin,$ymax,50510,"+L");
$axis->SetLabelColor(kRed);
$axis->Draw();

$gApplication->Run;
