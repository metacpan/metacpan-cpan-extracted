use strict;
use warnings;
use SOOT ':all';

my @xa;
my @ya;

my $c1 = TCanvas->new("c1");

my $ng = 100;
my $kNMAX = 10000;

my $cursor = $kNMAX;
my $g = TGraph->new($ng);
$g->SetMarkerStyle(21);
$g->SetMarkerColor(4);
my $x = 0.0;

while (1) {
  $c1->Clear();
  if ($cursor > $kNMAX-$ng) {
     foreach (0..$ng-1) {
       push @xa, $x;
       push @ya, sin($x);
       $x   += 0.1;
     }
     $g->Draw("alp");
     $cursor = 0;
  } 
  else {
    $x += 0.1;
    push @xa, $x;
    push @ya, sin($x);
    $cursor++;
    
    my @nxa;
    my @nya;
    for my $i ($cursor..$cursor+$ng-1) {
      push @nxa, $xa[$i];
      push @nya, $ya[$i];
    }
    $g->DrawGraph($ng, \@nxa, \@nya, "alp");
  }
  $c1->Update();
  $gSystem->ProcessEvents();
  $gSystem->Sleep(10);
}

