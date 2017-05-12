#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
   pipeline => 1,
   max_connections_per_host => 1,
);

$loop->add( $http );

my $peersock;
no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );
   $peersock->blocking(0);

   return Future->new->done( $self );
};

# Cancellation
{
   undef $peersock;
   my $f1 = $http->do_request(
      method  => "GET",
      uri     => URI->new( "http://host1/some/path" ),
   );

   wait_for { $peersock };

   $f1->cancel;

   wait_for { my $ret = sysread($peersock, my $buffer, 1); defined $ret and $ret == 0 };
   ok( 1, '$peersock closed' );

   # Retry after cancel should establish another connection

   undef $peersock;
   my $f2 = $http->do_request(
      method  => "GET",
      uri     => URI->new( "http://host1/some/path" ),
   );

   wait_for { $peersock };

   # Wait for the client to send its request
   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( join( $CRLF,
      "HTTP/1.1 200 OK",
      "Content-Type: text/plain",
      "Content-Length: 12",
      "" ) . $CRLF .
      "Hello world!"
   );

   wait_for { $f2->is_ready };
   $f2->get;
}

# Cancelling a pending unpipelined request
{
   undef $peersock;

   # Make first -one- request/response to establish HTTP/1.1 pipeline ability
   my $f0 = $http->do_request(
      method => "GET",
      uri    => URI->new( "http://host2/" ),
   );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( join( $CRLF,
      "HTTP/1.1 200 OK",
      "Content-Length: 0",
      "" ) . $CRLF
   );

   wait_for { $f0->is_ready };

   my ( $f1, $f2, $f3 ) = map {
      $http->do_request(
         method  => "GET",
         uri     => URI->new( "http://host2/req/$_" ),
      );
   } 1, 2, 3;

   wait_for { $peersock };

   # cancel $f2 - 1 and 3 should still complete
   $f2->cancel;

   # Wait for the $f1 and $f3
   $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   like( $request_stream, qr(^GET /req/1 HTTP/1.1), '$f1 request written' );
   $request_stream = "";

   $peersock->syswrite( join( $CRLF,
      "HTTP/1.1 200 OK",
      "Content-Length: 0",
      "" ) . $CRLF
   );

   wait_for { $f1->is_ready };
   ok( $f1->is_done, '$f1 is done' );

   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   like( $request_stream, qr(^GET /req/3 HTTP/1.1), '$f3 request written' );
   $request_stream = "";

   $peersock->syswrite( join( $CRLF,
      "HTTP/1.1 200 OK",
      "Content-Length: 0",
      "" ) . $CRLF
   );

   wait_for { $f3->is_ready };
   ok( $f3->is_done, '$f3 is done' );
}

done_testing;
