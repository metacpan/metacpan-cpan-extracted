#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP 0.02; # ->GET

use lib ".";
use t::Util;

use HTTP::Response;
use JSON::MaybeXS qw( decode_json );

use IO::Async::Loop;
use Net::Async::Matrix;

my $ua = Test::Async::HTTP->new;

my $matrix = Net::Async::Matrix->new(
   ua => $ua,
   server => "localserver.test",

   make_delay => sub { return Future->new },
);

ok( defined $matrix, '$matrix defined' );

ok( !defined $ua->next_pending, '$ua is idle initially' );

IO::Async::Loop->new->add( $matrix ); # for ->loop->new_future

# direct user_id + access_token
{
   my $login_f = $matrix->login(
      user_id => '@my-user-id:localserver.test',
      access_token => "0123456789ABCDEF",
   );

   ok( my $p = $ua->next_pending, '->login ID + token sends an HTTP request' );

   my $uri = $p->request->uri;
   is( $uri->authority, "localserver.test",                      '$req->uri->authority' );
   is( $uri->path,      "/_matrix/client/r0/sync",               '$req->uri->path' );
   is( { $uri->query_form }->{access_token}, "0123456789ABCDEF", '$req->uri->query_form access_token' );

   $p->respond( HTTP::Response->new( 200, "OK", [ "Content-Type" => "application/json" ], '{}' ) );

   ok( $login_f->is_ready, '->login ready with immediate user_id/access_token' );

   # clean up
   $matrix->stop;
   $ua->next_pending; # event stream
}

# user_id + password
{
   my $login_f = $matrix->login(
      user_id => '@my-user-id:localserver.test',
      password => 's3kr1t',
   );

   ok( my $p = $ua->next_pending, '->login ID + password sends an HTTP request' );

   is( $p->request->method, "GET", '$req->method' );
   is( $p->request->uri->path, "/_matrix/client/r0/login", '$req->uri->path' );

   respond_json( $p, {
      flows => [
         { type => "m.login.password", stages => [ "m.login.password" ] },
      ],
   });

   ok( $p = $ua->next_pending, 'Second HTTP request' );

   is( $p->request->method, "POST", '$req->method' );
   is( $p->request->uri->path, "/_matrix/client/r0/login", '$req->uri->path' );
   is_deeply( decode_json( $p->request->decoded_content ),
      {
         user     => '@my-user-id:localserver.test',
         type     => 'm.login.password',
         password => 's3kr1t',
      },
      '$req->content'
   );

   respond_json( $p, {
      user_id      => '@my-user-id:localserver.test',
      access_token => "0123456789ABCDEF"
   });

   ok( $p = $ua->next_pending, 'Third HTTP request' );

   my $uri = $p->request->uri;
   is( $uri->authority, "localserver.test",                      '$req->uri->authority' );
   is( $uri->path,      "/_matrix/client/r0/sync",               '$req->uri->path' );
   is( { $uri->query_form }->{access_token}, "0123456789ABCDEF", '$req->uri->query_form access_token' );

   $p->respond( HTTP::Response->new( 200, "OK", [ "Content-Type" => "application/json" ], '{}' ) );

   ok( $login_f->is_ready, '->login ready after server responds to POST' );

   # cleanup
   $matrix->stop;
   $ua->next_pending;
}

done_testing;
