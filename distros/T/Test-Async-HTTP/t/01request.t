#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Test::Async::HTTP;

use HTTP::Request;
use HTTP::Response;

my $http = Test::Async::HTTP->new;

ok( defined $http, 'defined $http' );

ok( !defined $http->next_pending, '->next_pending quiescent' );

# Trivial request
{
   my $f = $http->do_request(
      request => my $req = HTTP::Request->new(
         GET => "http://my.server/here",
      ),
   );

   isa_ok( $f, "Future", '$f from ->do_request' );
   ok( !$f->is_ready, '$f not yet ready' );

   ok( my $p = $http->next_pending, '->next_pending after ->do_request' );

   identical( $p->request, $req, '$p->request' );

   $p->respond( my $resp = HTTP::Response->new( 200, "OK", [], "Hello, world!" ) );

   ok( $f->is_ready, '$f is now ready' );
   identical( scalar $f->get, $resp, '$f->get is the response' );
}

# timeout
{
   my $f = $http->do_request(
      request => HTTP::Request->new(
         GET => "http://my.server/here",
      ),
      timeout => 20,
   );

   my $p = $http->next_pending;;
   is( $p->request->header( "X-NaHTTP-Timeout" ), 20, 'Timeout argument captured' );
}

done_testing;
