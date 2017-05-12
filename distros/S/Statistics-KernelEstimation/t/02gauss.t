# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Statistics-KernelEstimation.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
use Statistics::KernelEstimation;

#########################

# These are just basic sanity tests - testing the actual pdf/cdf calculations,
# and especially the bandwidth optimization will be harder.

$s = Statistics::KernelEstimation->new();

ok( defined $s, "Defined" );
ok( !defined scalar $s->range(), "Undef Range" );
ok( !defined $s->default_bandwidth(), "Undef Default" );
ok( !defined $s->optimal_bandwidth(), "Undef Optimal" );
ok( $s->count() == 0, "Count Zero" );


$s->add_data( 0 );
for( $y=0, $x=-10; $x<=10; $x+=0.01 ) {
  $y += ( gss( $x ) - $s->pdf( $x, 1 ) )**2;
}
$y *= 0.01;
almost( $y, 0, "Mean Square Error, Sgl Data Point" );


$s->add_data( 1 );
$s->add_data( 1 );
$s->add_data( -1, 2 );

ok( $s->count() == 5, "Count 5" );
ok( scalar $s->range() == 1, "Range Max" );
( $mn, $mx ) = $s->range();
ok( $mn == -1 && $mx == 1, "Range" );
ok( $s->default_bandwidth > 0, "Default Positive" );
ok( $s->optimal_bandwidth > 0, "Optimal Positive" );


for( $y=0, $x=-10; $x<=10; $x+=0.01 ) {
  $y += $s->pdf( $x, 1 );
}
$y *= 0.01;
almost( $y, 1, "PDF Normalized" );
almost( $s->cdf( 10, 1 ), 1, "CDF Normalized" );


# -----

sub gss {
  my ( $x, $m, $s ) = ( 0, 0, 1 );
  $x = shift if @_;
  $m = shift if @_;
  $2 = shift if @_;

  my $z = ( $x - $m )/$s;

  return exp(-0.5*$z**2 )/sqrt( 2*3.14159265358979323846*$s*$s );
}

sub almost {
  my ( $v1, $v2, $eps, $msg ) = ( 0, 0, 1e-5, '' );
  if( scalar @_ == 4 ) { 
    ( $v1, $v2, $eps, $msg ) = @_;
  } else {
    ( $v1, $v2, $msg ) = @_;
  }

  ok( abs( $v1 - $v2 ) < $eps, $msg );
}
