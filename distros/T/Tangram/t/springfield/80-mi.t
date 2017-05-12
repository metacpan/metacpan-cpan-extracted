

use strict;
use lib "t/springfield";
use Springfield;

Springfield::begin_tests(12);

{
   my $storage = Springfield::connect_empty;

   $storage->insert( NuclearPlant->new(
      name => 'Springfield Nuclear Power Plant',
      curies => 1_000_000 ) );

   $storage->disconnect();
}

sub mi_test
{
   my $base = shift;

   {
      my $storage = Springfield::connect;
      my ($plant) = $storage->select( $base );

      Springfield::test( $plant );
      Springfield::test( exists( $plant->{name} ) && $plant->{name} eq 'Springfield Nuclear Power Plant' );
      Springfield::test( exists( $plant->{curies} ) && $plant->{curies} == 1_000_000 );

      $storage->disconnect();
   }
   
   Springfield::leaktest;
}

mi_test( 'NuclearPlant' );
mi_test( 'Person' );
mi_test( 'EcologicalRisk' );
