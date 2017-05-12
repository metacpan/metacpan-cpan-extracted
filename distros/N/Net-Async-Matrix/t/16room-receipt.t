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

my $matrix = Net::Async::Matrix->new(
   ua => my $ua = Test::Async::HTTP->new,
   server => "localserver.test",

   make_delay => sub { Future->new },
);

IO::Async::Loop->new->add( $matrix ); # for ->loop->new_future
matrix_login( $matrix, $ua );

my $room = matrix_join_room( $matrix, $ua,
   {  type       => "m.room.member",
      room_id    => "!room:localserver.test",
      state_key  => '@sender:localserver.test',
      membership => "join",
   },
   {  type       => "m.room.member",
      room_id    => "!room:localserver.test",
      state_key  => '@reader:localserver.test',
      membership => "join",
   },
);

# receiving receipts
{
   my @events;
   $room->configure(
      on_read_receipt => sub {
         shift;
         push @events, [ @_ ];
      },
   );

   send_sync( $ua,
      rooms => {
         join => {
            '!room:localserver.test' => {
               ephemeral => {
                  events => [
                     {
                        type => "m.receipt",
                        content => {
                           '$123456789:localserver.test' => {
                              'm.read' => {
                                 '@reader:localserver.test' => { ts => 12345 } 
                              },
                           }
                        },
                     }
                  ],
               },
            }
         }
      }
   );

   is( scalar @events, 1, 'One event received' );

   my ( $member, $event_id, $content ) = @{ shift @events };
   is( $member->user->user_id, '@reader:localserver.test',    'member user ID' );
   is( $event_id,              '$123456789:localserver.test', 'event ID' );
   is_deeply( $content,        { ts => 12345 },               'content' );
}

# sending receipts
{
   my $f = $room->send_read_receipt( event_id => '$987654321:localserver.test' );

   my $p = next_pending_not_sync( $ua );
   is( $p->request->method, "POST", '$req->method' );
   is( $p->request->uri->path, '/_matrix/client/r0/rooms/!room:localserver.test/receipt/m.read/$987654321:localserver.test',
      '$req->uri->path' );

   respond_json( $p, {} );

   ok( $f->is_ready, '$f->is_ready' );
}

done_testing;
