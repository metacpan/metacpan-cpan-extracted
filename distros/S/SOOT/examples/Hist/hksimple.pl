use strict;
use warnings;
use SOOT ':all';
use constant kUPDATE => 10;

# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
# *-*
# *-*  This script illustrates the advantages of a TH1K histogram
# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

# Create a new canvas.
my $c1 = TCanvas->new("c1","Dynamic Filling Example",200,10,600,900);
$c1->SetFillColor(42);

# Create a normal histogram and two TH1K histograms
my @hpx;
$hpx[0] = TH1F->new("hp0","Normal histogram",1000,-4,4);
$hpx[1] = TH1K->new("hk1","Nearest Neighboor of order 3",1000,-4,4);
$hpx[2] = TH1K->new("hk2","Nearest Neighboor of order 16",1000,-4,4,16);
$c1->Divide(1,3);
for my $j (0..2) {
   $c1->cd($j+1); 
   $gPad->SetFrameFillColor(33);
   $hpx[$j]->SetFillColor(48);
   $hpx[$j]->Draw();
}

# Fill histograms randomly
$gRandom->SetSeed();
foreach (0..299) {
  my $px = $gRandom->Gaus(0.0,1.0);
  $hpx[$_]->Fill($px) for 0..2;
  padRefresh($c1) if $_ and $_ % kUPDATE == 0;
}

$hpx[$_]->Fit("gaus","","") for 0..2;

padRefresh($c1);

sub padRefresh {
  my $pad = shift;
  my $flag = shift || 0;

  return if not defined $pad;
  $pad->Modified();
  $pad->Update();
  my $tl = $pad->GetListOfPrimitives();
  return if not defined $tl;
  for (my $i = 0; $i < $tl->GetSize(); $i++) {
    my $obj = $tl->At($i);
    padRefresh($obj, 1) if $obj->isa("TPad");
  }
  return if ($flag);
  $gSystem->ProcessEvents();
}


$gApplication->Run;

