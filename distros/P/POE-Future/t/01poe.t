#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use POE;
use POE::Future;

# Quiet warning
POE::Kernel->run;

{
   my $future = POE::Future->new;

   POE::Session->create(
      inline_states => {
         _start => sub { $_[KERNEL]->delay( done => 0 ) },
         done   => sub { $future->done( "result" ) },
      }
   );

   is( [ $future->get ], [ "result" ], '$future->get on POE::Future' );
}

done_testing;
