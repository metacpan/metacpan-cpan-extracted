#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

foreach my $close ( 0, 1, 2 ) {
   # We'll run an almost-identical test three times, with different server responses.
   # 0 == keepalive
   # 1 == close
   # 2 == close with no Content-Length

   my $peersock;
   my $connections = 0;

   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      $connections++;

      $args{host}    eq "host$close" or die "Expected $args{host} eq host$close";
      $args{service} eq "80"         or die "Expected $args{service} eq 80";

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   my $response;

   # placate IO::Async bug where this returns () instead of 0
   is( scalar $http->children || 0, 0, 'scalar $http->children 0 initially' );

   my $future = $http->do_request(
      uri => URI->new( "http://host$close/first" ),

      on_response => sub { $response = $_[0] },
      on_error    => sub { die "Test died early - $_[0]" },
   );

   ok( defined $future, 'defined $future' );

   wait_for { $peersock };
   is( $connections, 1, '->connect called once for first request' );
   is( scalar $http->children, 1, 'scalar $http->children 1 after first request' );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   my $req_firstline = $1;

   is( $req_firstline, "GET /first HTTP/1.1", 'First line for first request' );

   ok( !$future->is_ready, '$future is not ready before response given' );

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        ( $close == 2 ? "" : "Content-Length: 3$CRLF" ) .
                        "Content-Type: text/plain$CRLF" .
                        ( $close ? "Connection: close$CRLF" : "Connection: Keep-Alive$CRLF" ) .
                        "$CRLF" .
                        "1st" );
   $peersock->close, undef $peersock if $close;

   undef $response;
   wait_for { defined $response };

   if( $close ) {
      is( scalar $http->children, 0, 'scalar $http->children now 0 again after first response' );
   }
   else {
      is( scalar $http->children, 1, 'scalar $http->children still 1 after first response' );
   }

   is( $response->content, "1st", 'Content of first response' );
   identical( scalar $future->get, $response, '$future->get for first request' );

   my $inner_response;
   my $inner_future;
   $future = $http->do_request(
      uri => URI->new( "http://host$close/second" ),

      on_response => sub {
         $response = $_[0];
         $inner_future = $http->do_request(
            uri => URI->new( "http://host$close/inner" ),
            on_response => sub { $inner_response = $_[0] },
            on_error    => sub { die "Test died early - $_[0]" },
         );
      },
      on_error    => sub { die "Test died early - $_[0]" },
   );

   wait_for { $peersock };

   if( $close ) {
      is( $connections, 2, '->connect called again for second request to same server' );
   }
   else {
      is( $connections, 1, '->connect not called again for second request to same server' );
   }

   is( scalar $http->children, 1, 'scalar $http->children 1 after second request to same server' );

   $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   $req_firstline = $1;

   is( $req_firstline, "GET /second HTTP/1.1", 'First line for second request' );

   ok( !$future->is_ready, '$future is not ready before response given for second request' );

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        ( $close == 2 ? "" : "Content-Length: 3$CRLF" ) .
                        "Content-Type: text/plain$CRLF" .
                        ( $close ? "Connection: close$CRLF" : "Connection: Keep-Alive$CRLF" ) .
                        "$CRLF" .
                        "2nd" );
   $peersock->close, undef $peersock if $close;

   undef $response;
   wait_for { defined $response };

   is( $response->content, "2nd", 'Content of second response' );
   identical( scalar $future->get, $response, '$future->get for second request' );

   ok( defined $inner_future, 'defined $inner_future' );

   wait_for { $peersock };

   if( $close ) {
      is( $connections, 3, '->connect called again for inner request to same server' );
   }
   else {
      is( $connections, 1, '->connect not called again for inner request to same server' );
   }

   $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   $req_firstline = $1;

   is( $req_firstline, "GET /inner HTTP/1.1", 'First line for inner request' );

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        ( $close == 2 ? "" : "Content-Length: 3$CRLF" ) .
                        "Content-Type: text/plain$CRLF" .
                        ( $close ? "Connection: close$CRLF" : "Connection: Keep-Alive$CRLF" ) .
                        "$CRLF" .
                        "3rd" );
   $peersock->close if $close;

   undef $inner_response;
   wait_for { defined $inner_response };

   is( $inner_response->content, "3rd", 'Content of inner response' );
   identical( scalar $inner_future->get, $inner_response, '$inner_future->get for inner request' );

   if( $close ) {
      is( scalar $http->children, 0, 'scalar $http->children now 0 again after inner response' );
   }
   else {
      is( scalar $http->children, 1, 'scalar $http->children still 1 after inner response' );
   }

   # Drain connections for next test
   undef $peersock;
   wait_for { scalar $http->children == 0 };
}

done_testing;
