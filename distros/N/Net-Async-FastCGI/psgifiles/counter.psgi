#!/usr/bin/perl

use strict;

use IO::Async::Timer::Periodic;

sub {
   my $env = shift;
   return sub {
      my $responder = shift;

      my $writer = $responder->([
         200,
         [ 'Content-Type' => "text/plain" ],
      ]);

      my $counter = 1;
      my $timer = IO::Async::Timer::Periodic->new(
         interval => 1,
         on_tick => sub {
            $writer->write( "$counter\r\n" );
            $counter++
         },
      );
      $timer->start;
      
      $env->{'io.async.loop'}->add( $timer );
   };
}
