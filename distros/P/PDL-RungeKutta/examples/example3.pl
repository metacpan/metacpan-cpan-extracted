#!/usr/bin/perl -w
use PDL;
use PDL::NiceSlice;
use PDL::RungeKutta;
#use PDL::Graphics::PGPLOT::Window;

#$win1 = PDL::Graphics::PGPLOT::Window->new( Device      => "/xserve",
#                                            WindowWidth => 6);

$n0=50;             # initial number of steps per average Larmor period
$Bmax=1.e-9;
$pi=3.14159265358979;
$m =  9.10938188e-31;  # electron mass
$q = -1.602176462e-19; # electron charge


$rv0=pdl(0,0,0,1.e5,2.e5,0); # initial position and velocity
$t0  = 0;	# begining os integration
$Tl  = 2*$pi*$m/(abs($q)*$Bmax);    # Larmor period
$dt0 = $Tl/($n0-1);                 # initial time step
$t1  = 20*$Tl;   # end of integration
$eps= 1.e-6; # error
$verbose=1;

@esargs=($m,$q,\&field,$t0,$t1); # arguments for error-scale function

($evt,$evrv,$evd,$i,$j)=
rkevolve($t0,$rv0,$dt0,\&difeq,$t1,$eps,\&ersceval,\@esargs,$verbose);

wcols $evrv((0),),$evrv((1),),$evrv((2),),$evrv((3),),$evrv((4),),$evrv((5),),'test.dat';
#$win1->line($evrv((0),),$evrv((1),),{COLOR=>'red'});

sub difeq {         # motion law
  my ($t,$y)= @_;
  my $yd=zeroes(6);  # y=(R,V)
  $yd(:2).=$y(3:);                                            # R'=V
  $yd(3:).=$q/$m*crossp($y(3:),field($y(:2),$t,$t0,$t1));     # V'=q(BxV)/m
  return $yd;
}

sub ersceval {      #error-scale evaluation
  my ($t,$rv,$m,$q,$fld,$t0,$t1) = @_;
  my $es=ones(6);
  my $B=&$fld($rv(0:2),$t,$t0,$t1);
  $es(:2).=abs($m*sumover($rv(3:1) x $B)/($q*sumover($B**2))); # Larmor radius
  $es(3:).=sqrt(sumover($rv(3:)**2)); # module of velocity
  return $es;
}

sub field {
  my ($r,$t,$t0,$T) = @_;
  $scale=($t-$t0)/$T*1.e-9;
  my $B = pdl(0,0,1)*$scale;
  return $B;
}

