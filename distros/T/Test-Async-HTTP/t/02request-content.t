#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Async::HTTP;

use HTTP::Request;
use HTTP::Response;

my $http = Test::Async::HTTP->new;

my $resp_ok = HTTP::Response->new( 200, "OK", [], "" );

# content as string
{
   my $written_length;
   my $f = $http->do_request(
      request => HTTP::Request->new( GET => "http://my.server/here" ),
      request_body => "Content from a string",
      on_body_write => sub { $written_length += $_[0] },
   );

   ok( my $p = $http->next_pending, '->next_pending' );

   is( $p->request->content, "Content from a string", '->content of pending request via string' );
   is( $written_length, 21, 'Written length observed by on_body_write' );

   $p->respond( $resp_ok );
}

# content as Future
{
   my $f = $http->do_request(
      request => HTTP::Request->new( GET => "http://my.server/here" ),
      request_body => Future->done( "Content from a Future" ),
   );

   ok( my $p = $http->next_pending, '->next_pending' );

   is( $p->request->content, "Content from a Future", '->content of pending request via Future' );

   $p->respond( $resp_ok );
}

# content as CODE
{
   my @content = ( "Content from ", "CODE" );

   my $f = $http->do_request(
      request => HTTP::Request->new( GET => "http://my.server/here" ),
      request_body => sub { shift @content },
   );

   ok( my $p = $http->next_pending, '->next_pending' );

   is( $p->request->content, "Content from CODE", '->content of pending request via CODE' );

   $p->respond( $resp_ok );
}

done_testing;
