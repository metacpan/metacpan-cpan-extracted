#!/usr/bin/perl

use strict;

sub {
   my $env = shift;
   return sub {
      my $respond = shift;

      $env->{'io.async.loop'}->enqueue_timer(
         delay => 3,
         code => sub {
            $respond->([
               200,
               [ 'Content-Type' => 'text/plain' ],
               [ "Hello World\n" ],
            ]);
         },
      );
   };
}
