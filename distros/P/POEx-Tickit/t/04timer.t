#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Time::HiRes qw( time );

use POE;
use POEx::Tickit;

my $tickit;

my $tick;

POE::Session->create(
   inline_states => {
      _start => sub {
         pipe( my ( $my_rd, $term_wr ) ) or die "Cannot pipepair - $!";

         $tickit = POEx::Tickit->new(
            term_out => $term_wr,
         );

         $tickit->timer( after => 0.1, sub { $tick++; $tickit->stop } );
      },
   },
);

POE::Kernel->run;

is( $tick, 1, '$tick 1 after "after" timer' );

done_testing;
