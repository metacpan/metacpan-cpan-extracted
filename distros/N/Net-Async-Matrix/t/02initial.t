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

my $ua = Test::Async::HTTP->new;

my @rooms;
my $matrix = Net::Async::Matrix->new(
   ua => $ua,
   server => "localserver.test",

   first_sync_limit => 20,

   on_room_new => sub {
      push @rooms, $_[1];
   },

   make_delay => sub { Future->new },
);

IO::Async::Loop->new->add( $matrix ); # for ->loop->new_future

my $login_f = $matrix->login(
   user_id => '@my-test-user:localserver.test',
   access_token => "0123456789ABCDEF",
);

ok( my $p = $ua->next_pending, '->start sends an HTTP request' );

my $uri = $p->request->uri;

is( $uri->authority, "localserver.test",        '$req->uri->authority' );
is( $uri->path,      "/_matrix/client/r0/sync", '$req->uri->path' );
is_deeply(
   { $uri->query_form },
   { access_token => "0123456789ABCDEF",
     filter       => '{"room":{"timeline":{"limit":20}}}' },
   '$req->uri->query_form' );

respond_json( $p, {
   next_batch => "next_token_here",
   rooms => {
      join => {
         "!id-for-a-room:localserver.test" => {
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
      },
   },
   presence => {
      events => [],
   },
});

ok( $login_f->is_ready, '->login ready after initial sync' );
$login_f->get;

ok( $matrix->start->is_ready, '->start is already ready' );

is( scalar @rooms, 1, '@rooms has a room object' );

is( $rooms[0]->room_id, "!id-for-a-room:localserver.test", '$rooms[0]->room_id' );

# Should make a start on GET /events

ok( $p = $ua->next_pending, 'another request after initialSync' );
is( $p->request->method, "GET", 'request method is GET' );
is( $p->request->uri->path, "/_matrix/client/r0/sync", 'request path is /sync' );

# Just leave it dangling at EOF

done_testing;
