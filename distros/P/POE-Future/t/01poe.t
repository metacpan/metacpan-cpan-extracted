#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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

   is_deeply( [ $future->get ], [ "result" ], '$future->get on POE::Future' );
}

done_testing;
