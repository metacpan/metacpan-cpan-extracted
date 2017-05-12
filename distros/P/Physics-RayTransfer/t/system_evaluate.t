use strict;
use warnings;

use Test::More;

use Physics::RayTransfer;

{
  # space-space system

  my $sys = Physics::RayTransfer->new();
  isa_ok( $sys, 'Physics::RayTransfer' );

  $sys->add_space(2);
  $sys->add_space(3);

  is( scalar @{ $sys->elements }, 2, "Correct number of elements" );

  my $expected = [1,5,0,1];
  my $eval = $sys->evaluate;

  is_deeply( $eval->as_arrayref, $expected, "space-space" );
}

{
  # space-obs-space system

  my $sys = Physics::RayTransfer->new();
  isa_ok( $sys, 'Physics::RayTransfer' );

  $sys->add_space(2);
  $sys->add_observer;
  $sys->add_space(3);

  is( scalar @{ $sys->elements }, 3, "Correct number of elements" );

  my $expected = [1,2,0,1];
  my $eval = $sys->evaluate;

  is_deeply( $eval->as_arrayref, $expected, "space-obs-space" );
}

{
  # two space and right mirror system 

  my $sys = Physics::RayTransfer->new();
  isa_ok( $sys, 'Physics::RayTransfer' );

  $sys->add_space(2);
  $sys->add_space(3);
  $sys->add_mirror;

  is( scalar @{ $sys->elements }, 3, "Correct number of elements" );

  my $expected = [1,10,0,1];
  my $eval = $sys->evaluate;

  is_deeply( $eval->as_arrayref, $expected, "space-space-mirror" );
}

{
  # space-obs-space-mirror

  my $sys = Physics::RayTransfer->new();
  isa_ok( $sys, 'Physics::RayTransfer' );

  $sys->add_space(2);
  $sys->add_observer;
  $sys->add_space(3);
  $sys->add_mirror;

  is( scalar @{ $sys->elements }, 4, "Correct number of elements" );

  my $expected = [1,8,0,1];
  my $eval = $sys->evaluate;

  is_deeply( $eval->as_arrayref, $expected, "space-obs-space-mirror" );
}

{
  # mirror-space-space (left mirror is useless)

  my $sys = Physics::RayTransfer->new();
  isa_ok( $sys, 'Physics::RayTransfer' );

  $sys->add_mirror;
  $sys->add_space(2);
  $sys->add_space(3);

  is( scalar @{ $sys->elements }, 3, "Correct number of elements" );

  my $expected = [1,5,0,1];
  my $eval = $sys->evaluate;

  is_deeply( $eval->as_arrayref, $expected, "mirror-space-space" );
}

{
  # mirror-space-space-mirror (cavity) 

  my $sys = Physics::RayTransfer->new();
  isa_ok( $sys, 'Physics::RayTransfer' );

  $sys->add_mirror;
  $sys->add_space(2);
  $sys->add_space(3);
  $sys->add_mirror;

  is( scalar @{ $sys->elements }, 4, "Correct number of elements" );

  my $expected = [1,10,0,1];
  my $eval = $sys->evaluate;

  is_deeply( $eval->as_arrayref, $expected, "mirror-space-space-mirror (cavity)" );
}

done_testing;


