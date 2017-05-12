#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Async::HTTP;

use HTTP::Request;
use HTTP::Response;

my $http = Test::Async::HTTP->new;

# single ->respond
{
   my $resp_header;
   my $resp_content = "";
   my $f = $http->do_request(
      request => HTTP::Request->new( GET => "http://my.server/here" ),
      on_header => sub {
         ( $resp_header ) = @_;
         return sub { # on_chunk
            @_ ? $resp_content .= $_[0] : return "Final result";
         };
      },
   );

   ok( my $p = $http->next_pending, '->next_pending after ->do_request with on_header' );

   $p->respond( HTTP::Response->new( 200, "OK", [ Content_type => "text/plain" ],
         "The response content"
   ) );

   ok( $f->is_ready, '$f is now ready' );
   is( scalar $f->get, "Final result", '$f->get yields on_chunk final result' );
   is( $resp_header->content_type, "text/plain", '$resp_header has content type' );
   ok( !length $resp_header->content, '$resp_header has no content' );
   is( $resp_content, "The response content", '$resp_content' );
}

# ->respond_header, ->respond_more, ->respond_done
{
   my $resp_header;
   my $resp_content = "";
   my $f = $http->do_request(
      request => HTTP::Request->new( GET => "http://my.server/here" ),
      on_header => sub {
         ( $resp_header ) = @_;
         return sub { # on_chunk
            @_ ? $resp_content .= $_[0] : return "Final result";
         };
      },
   );

   my $p = $http->next_pending;

   $p->respond_header( HTTP::Response->new( 200, "OK", [ Content_type => "text/plain" ] ) );

   ok( $resp_header, '$resp_header after ->respond_header' );
   is( $resp_header->content_type, "text/plain", '$resp_header has content type' );

   $p->respond_more( "Some chunked content" );

   is( $resp_content, "Some chunked content", '$resp_content after ->resp_content' );

   $p->respond_done;

   ok( $f->is_ready, '$f is now ready' );
}

done_testing;
