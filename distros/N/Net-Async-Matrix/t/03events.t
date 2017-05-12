#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP 0.02; # ->GET

use lib ".";
use t::Util;

use IO::Async::Loop;
use Net::Async::Matrix;
use Future;

my $matrix = Net::Async::Matrix->new(
   ua => my $ua = Test::Async::HTTP->new,
   server => "localserver.test",

   make_delay => sub { Future->new },
);

IO::Async::Loop->new->add( $matrix ); # for ->loop->new_future
matrix_login( $matrix, $ua );

# presence event
{
   my ( $user, %presence );
   $matrix->configure(
      on_presence => sub { shift; ( $user, %presence ) = @_ },
   );

   send_sync( $ua,
      presence => { events => [
         {
            type    => "m.presence",
            sender  => '@some_user:server',
            content => {
               presence => "online",
            },
         }
      ] },
   );

   is( $user->user_id, '@some_user:server', '$user for on_presence event' );
   is( $presence{presence}[1], "online", '{presence} for on_presence event' );

   # cleanup
   $matrix->stop;
   $ua->next_pending;
}

# enable_events = false
{
   $matrix->configure(
      enable_events => 0,
   );
   matrix_login( $matrix, $ua );

   my $p;
   ok( !( $p = $ua->next_pending ), 'UA is now idle after login with enable_events false' ) or
      diag( "Request was for " . $p->request->uri );
}

done_testing;
