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

# join by direct ID
{
   my $f = $matrix->join_room( "!abcdef12345:localserver.test" );
   ok( defined $f, '$f from ->join_room' );

   ok( my $p = next_pending_not_sync( $ua ), '->join_room ID sends an HTTP request' );

   is( $p->request->method, "POST", '$req->method' );
   my $uri = $p->request->uri;
   is( $uri->authority, "localserver.test", '$req->uri->authority' );
   is( $uri->path,      "/_matrix/client/r0/join/!abcdef12345:localserver.test",
      '$req->uri->path' );

   respond_json( $p, { room_id => "!abcdef12345:localserver.test" } );

   send_sync( $ua,
      rooms => {
         join => {
            '!abcdef12345:localserver.test' => {
               timeline => {},
               state => {
                  events => [],
               },
            }
         }
      }
   );

   ok( $f->is_ready, '$f now ready after /state response' );
   isa_ok( my $room =  $f->get, "Net::Async::Matrix::Room", '$f->get returns a room' );

   ok( $room->await_synced->is_ready, '$room->await_synced is already ready' );
}

done_testing;
