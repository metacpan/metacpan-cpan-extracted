use strict;
use warnings;
use SOOT ':all';
use constant NBINS => 20;

my $stack = shift;
my $c1 = TCanvas->new;

my $hs = THStack->new("hs","three plots")->keep;
my @colors = (kBlue, kRed, kYellow);
my @names  = qw(h1 h2 h3);
my @h = map {
  my $h = TH2F->new(($names[$_]) x 2, NBINS,-4,4, NBINS,-4,4);
  $h->keep;
  $h->SetFillColor($colors[$_]);
  $hs->Add($h);
  $h
} 0..$#names;

my $r = TRandom->new;

$h[0]->Fill($r->Gaus(), $r->Gaus()) for 1..20000; 

foreach (1..200) {
  my $ix = int($r->Uniform(0, NBINS));
  my $iy = int($r->Uniform(0, NBINS));
  my $bin = $h[0]->GetBin($ix, $iy);
  my $val = $h[0]->GetBinContent($bin);
  next if $val <= 0;
  $h[0]->SetBinContent($bin,0) if not $stack;
  if ($r->Rndm() > 0.5) {
    $h[1]->SetBinContent($bin, 0) if not $stack;
    $h[2]->SetBinContent($bin, $val);
  } 
  else {
    $h[2]->SetBinContent($bin, 0) if not $stack;
    $h[1]->SetBinContent($bin, $val);
  }
}
$hs->Draw("lego1");

$gApplication->Run;      

