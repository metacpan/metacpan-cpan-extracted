use strict;
use warnings;
use SOOT ':all';

sub _binomialSimple {
  #
  # Simple test for the binomial distribution
  #
  printf("\nTMath:::Binomial simple test\n");
  printf("Build the Tartaglia triangle\n");
  printf("============================\n");
  use constant max => 13;
  foreach my $i (0..max-1) {
    printf "n=%2d", $i;
    print "  " x (max-$i);
    for my $j (0..$i) {
      my $bin = TMath::Nint( TMath::Binomial($i,$j));
      printf("%4d", $bin);
    } 
    print "\n";
  }
}

sub _binomialFancy {
  my $serr = 0;
  use constant nmax => 10000;

  print <<'VERBATIM';

TMath:::Binomial fancy test
Verify Newton formula for (x+y)^n
x,y in [-2,2] and n from 0 to 9
=================================
VERBATIM
  my $val = 0.;
  my ($x, $y);
  for (0..nmax-1) {
    do {
        $x = 2 * (1 - 2*rand());
        $y = 2 * (1 - 2*rand());
        $val = abs($x+$y)*1.;
    } while ($val < 0.75); # Avoid large cancellations

    foreach my $j (0..9) {
       my $res1 = ($x+$y) ** $j;
       my $res2 = 0;
       foreach my $k (0..$j) {
          $res2 += $x**$k
                 * $y**($j-$k)
                 * TMath::Binomial($j,$k);
       }
       my $err = abs($res1-$res2)/abs($res1);
       print "res1=$res1 res2=$res2 x=$x y=$y err=$err j=$j\n" if $err > 1e-10;
     
       $serr += $err;
     }
  }
  print "Average Error = ". $serr/nmax . "\n";
}

_binomialSimple;
_binomialFancy;


