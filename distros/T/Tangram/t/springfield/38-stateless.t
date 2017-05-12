

# wtf is this testing anyway?

use strict;
use lib 't/springfield';
use Springfield;

Springfield::begin_tests(5);

my $plant_id;

{
   my $storage = Springfield::connect_empty;

   $plant_id = $storage->insert(
      NuclearPlant->new( employees => [ NaturalPerson->new( firstName => 'Homer' ) ] ) );

   $storage->disconnect;
}

Springfield::leaktest;

{
   my $storage = Springfield::connect;

   my $plant = $storage->load( $plant_id );
   Springfield::test( @{ $plant->{employees} } == 1 && $plant->{employees}[0]{firstName} eq 'Homer' );

   $storage->disconnect;
}

Springfield::leaktest;

{
   my $storage = Springfield::connect;

   my ($plant) = $storage->select( 'NuclearPlant' );
   Springfield::test( @{ $plant->{employees} } == 1 && $plant->{employees}[0]{firstName} eq 'Homer' );

   $storage->disconnect;
}

Springfield::leaktest;

1;
