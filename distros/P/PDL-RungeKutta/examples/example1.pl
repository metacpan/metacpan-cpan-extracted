#!/usr/bin/perl -w
use PDL;
use PDL::Math;
use PDL::NiceSlice;
use PDL::RungeKutta;

#  solve y' = 1/x, y(1) = 0 , x in [1,100]
#  Solution: y = ln(x)

$Y0=zeroes(1);          # y(1)=0
@esargs=();             # extra arguments for error evaluation function
$t0=1;                  # initial moment
$dt0=0.1;               # initial time step
$t1=100;                # final moment
$eps=1.e-9;             # requested error
$verbose=0;

# integration
($evt,$evy,$evd,$i,$j) = 
rkevolve($t0,$Y0,$dt0,\&DE,$t1,$eps,\&error,\@esargs,$verbose);

$check=log($evt);
wcols "%15.10f",$evt,$evy((0)),$check,$evd((0)),'test.dat',
{ HEADER => "#        t          y computed        y exact        error" };

print "\n$i steps\n$j times reset\nresults writed in test.dat\n";

sub DE {                # differential eq
  my ($t,$y)= @_;
  my $yd=ones(1)/$t;
  return $yd;
}

sub error {             # error scale 
  my ($t,$Y) = @_;
  my $es=ones(1);
  return $es;
}
