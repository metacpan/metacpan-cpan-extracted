#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP 0.02; # ->GET
use JSON::MaybeXS qw( decode_json );

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
);

# send message
{
   my $f = $room->send_message(
      type => "m.text",
      body => "Here is the message",
   );

   my $p = next_pending_not_sync( $ua );
   is( $p->request->method, "POST", '$req->method' );
   is( $p->request->uri->path, "/_matrix/client/r0/rooms/!room:localserver.test/send/m.room.message",
      '$req->uri->path' );
   is_deeply( decode_json( $p->request->decoded_content ),
      { msgtype => "m.text", body => "Here is the message" },
      '$req->content' );

   respond_json( $p, { event_id => "!ABCDE:localserver.test" } );

   ok( $f->is_ready, '$f is ready' );
   is( $f->get, "!ABCDE:localserver.test", '$f->get returns event ID' );
}

# send with txn_id
{
   my $f = $room->send_message(
      type => "m.text",
      body => "Here is another message",
      txn_id => "123ABCD",
   );

   my $p = next_pending_not_sync( $ua );
   is( $p->request->method, "PUT", '$req->method' );
   is( $p->request->uri->path, "/_matrix/client/r0/rooms/!room:localserver.test/send/m.room.message/123ABCD",
      '$req->uri->path' );

   respond_json( $p, { event_id => "!FGHIJ:localserver.test" } );

   ok( $f->is_ready, '$f is ready' );
   is( $f->get, "!FGHIJ:localserver.test", '$f->get returns event ID' );
}

# receive message
{
   my @messages;
   $room->configure(
      on_message => sub {
         shift;
         push @messages, [ @_ ];
      },
   );

   send_sync( $ua,
      rooms => {
         join => {
            "!room:localserver.test" => {
               timeline => {
                  events => [
                     {
                        type    => "m.room.message",
                        room_id => "!room:localserver.test",
                        sender  => '@sender:localserver.test',
                        content => {
                           msgtype => "m.text",
                           body    => "And here is the response",
                        },
                     },
                  ]
               }
            }
         }
      }
   );

   ok( scalar @messages, 'Received a room message' );
   my $e = shift @messages;

   is( $e->[0]->user->user_id, '@sender:localserver.test', 'event $sender' );
   is_deeply( $e->[1], { msgtype => "m.text", body => "And here is the response" },
      'event $content' );
}

done_testing;
