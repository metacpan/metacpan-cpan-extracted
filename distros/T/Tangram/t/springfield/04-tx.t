

use strict;
use lib 't/springfield';
use Springfield;

Springfield::begin_tests(4);

Springfield::connect_empty()->disconnect(); # init $no_tx

Springfield::tx_tests(4, sub {

{
   my $storage = Springfield::connect_empty;
   my $homer = NaturalPerson->new( firstName => 'Homer', name => 'Simpson' );

   Springfield::test( !defined $storage->id( $homer ) );

   eval
   {
      $storage->tx_do(
         sub
         {
            $storage->insert( $homer );
            Springfield::test( defined $storage->id( $homer ) );
            die;
         } );
   };

   Springfield::test( !defined $storage->id( $homer ) );

   $storage->disconnect();
}

Springfield::leaktest;

} ); # tx_tests
