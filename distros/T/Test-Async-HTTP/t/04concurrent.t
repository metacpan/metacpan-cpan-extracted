#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Async::HTTP;

use HTTP::Request;
use HTTP::Response;

my $http = Test::Async::HTTP->new;

ok( defined $http, 'defined $http' );

{
   my $f1 = $http->do_request(
      request => HTTP::Request->new( GET => "http://my.server/1" ),
   );
   my $f2 = $http->do_request(
      request => HTTP::Request->new( GET => "http://my.server/2" ),
   );

   # Order
   my $p = $http->next_pending;
   is( $p->request->uri, "http://my.server/1", 'request URI of first pending' );
   $p->respond( HTTP::Response->new( 200, "OK", [], "Response 1" ) );

   ok( $f1->is_ready, '$f1 now ready after first response' );
   is( $f1->get->content, "Response 1", 'First response' );

   $p = $http->next_pending;
   is( $p->request->uri, "http://my.server/2", 'request URI of second pending' );
   $p->respond( HTTP::Response->new( 200, "OK", [], "Response 2" ) );

   ok( $f2->is_ready, '$f2 now ready after second response' );
   is( $f2->get->content, "Response 2", 'Second response' );
}

done_testing;
