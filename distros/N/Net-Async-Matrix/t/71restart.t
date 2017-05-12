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

my $room = matrix_join_room( $matrix, $ua,
   {  type       => "m.room.member",
      room_id    => "!room:localserver.test",
      state_key  => '@sender:localserver.test',
      membership => "join",
   },
);

$matrix->stop;
pass( '$matrix->stop' );

$matrix->start;

my $p = $ua->next_pending;
is( $p->request->uri->path, "/_matrix/client/r0/sync", '$req->uri->path' );

respond_json( $p, {
   next_batch => "next_token_here",
   presence => {
      events => [],
   },
   rooms => {
      join => {
         '!room:localserver.test' => {
            timeline => {
               limited    => '',
               prev_batch => '',
               events     => [],
            },
            state => {
               events => [],
            },
            account_data => {
               events => [],
            },
            ephemeral => {
               events => [],
            },
         },
      }
   },
});

pass( '$matrix->start does not fail' );

done_testing;
