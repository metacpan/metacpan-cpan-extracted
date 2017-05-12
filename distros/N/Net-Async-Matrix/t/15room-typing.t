#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP 0.02; # ->GET
use JSON::MaybeXS qw( decode_json );
use List::Util qw( min );

use lib ".";
use t::Util;

use IO::Async::Loop;
use Net::Async::Matrix;
use Future;

my @timers;

sub warp_time
{
   my ( $secs ) = @_;

   while( $secs ) {
      my $advance = min map { $_->[0] } @timers;
      $advance = $secs if $advance > $secs;

      $_->[0] -= $advance for @timers;
      $secs -= $advance;

      $_->[0] or $_->[1]->done() for @timers;

      @timers = grep { $_->[0] > 0 } @timers;
   }
}

my $matrix = Net::Async::Matrix->new(
   ua => my $ua = Test::Async::HTTP->new,
   server => "localserver.test",

   make_delay => sub {
      my ( $secs ) = @_;
      push @timers, [ $secs, my $f = Future->new ];
      return $f;
   },
);

IO::Async::Loop->new->add( $matrix ); # for ->loop->new_future
matrix_login( $matrix, $ua );

my $room = matrix_join_room( $matrix, $ua,
   {  type       => "m.room.member",
      room_id    => "!room:localserver.test",
      state_key  => '@sender:localserver.test',
      membership => "join",
   },
);

my $TIMEOUT = Net::Async::Matrix::Room->TYPING_RESEND_SECONDS;

# start typing
{
   $room->typing_start;

   my $p = next_pending_not_sync( $ua );
   is( $p->request->method, "PUT", '$req->method' );
   is( $p->request->uri->path, "/_matrix/client/r0/rooms/!room:localserver.test/typing/\@my-test-user:localserver.test",
      '$req->uri->path' );
   is_deeply( decode_json( $p->request->decoded_content ),
      { typing => 1, timeout => ( $TIMEOUT + 5 ) * 1000 },
      '$req->content' );

   respond_json( $p, {} );
}

# timer expires
{
   # We ought to have a timer in the list of $TIMEOUT seconds
   ok( scalar( grep { $_->[0] == $TIMEOUT } @timers ),
      'A timer exists for the appropriate timeout' );

   warp_time( $TIMEOUT );

   ok( my $p = next_pending_not_sync( $ua ), 'Second request sent after timeout' );
   is( $p->request->method, "PUT", '$req->method' );
   is( $p->request->uri->path, "/_matrix/client/r0/rooms/!room:localserver.test/typing/\@my-test-user:localserver.test",
      '$req->uri->path' );
   is_deeply( decode_json( $p->request->decoded_content ),
      { typing => 1, timeout => ( $TIMEOUT + 5 ) * 1000 },
      '$req->content' );

   respond_json( $p, {} );
}

# stop typing
{
   $room->typing_stop;

   my $p = next_pending_not_sync( $ua );
   is( $p->request->method, "PUT", '$req->method' );
   is( $p->request->uri->path, "/_matrix/client/r0/rooms/!room:localserver.test/typing/\@my-test-user:localserver.test",
      '$req->uri->path' );
   is_deeply( decode_json( $p->request->decoded_content ),
      { typing => 0 },
      '$req->content' );

   respond_json( $p, {} );
}

done_testing;
