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

my $test_mode;

# Most of this function copypasted from t/01http-req.t
sub do_uris
{
   my %wait;
   my $wait_id = 0;

   my $http = Net::Async::HTTP->new( pipeline => not( $test_mode eq "no_pipeline" ) );
   $loop->add( $http );

   my $peersock;

   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      $args{service} eq "80" or die "Expected $args{service} eq 80";

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   while( my ( $uri, $on_resp ) = splice @_, 0, 2 ) {
      $wait{$wait_id} = 1;

      my $id = $wait_id;

      $http->do_request(
         uri     => $uri,
         method  => 'GET',

         timeout => 10,

         on_response => sub { $on_resp->( @_ ); delete $wait{$id} },
         on_error    => sub { die "Test failed early - $_[-1]" },
      );

      $wait_id++;
   }

   my $request_stream = "";
   my $not_first = 0;

   while( keys %wait ) {
      # Wait for the client to send its request
      wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

      $request_stream =~ s/^(.*)$CRLF//;
      my $req_firstline = $1;

      $request_stream =~ s/^(.*?)$CRLF$CRLF//s;
      my %req_headers = map { m/^(.*?):\s+(.*)$/g } split( m/$CRLF/, $1 );

      if( $test_mode ne "pipeline" ) {
         is( length $request_stream, 0, "Stream is idle after request for $test_mode" );
      }
      elsif( keys %wait > 1 && $not_first++ ) {
         # Just in case it wasn't flushed yet, wait for another request to be
         # written anyway before we respond to this one
         wait_for_stream { length $request_stream } $peersock => $request_stream;
         ok( length $request_stream > 0, "Stream is not idle after middle request for $test_mode" );
      }

      my $req_content;
      if( defined( my $len = $req_headers{'Content-Length'} ) ) {
         wait_for { length( $request_stream ) >= $len };

         $req_content = substr( $request_stream, 0, $len );
         substr( $request_stream, 0, $len ) = "";
      }

      my $waitcount = keys %wait;

      my $body = "$req_firstline";

      my $protocol = "HTTP/1.1";
      $protocol = "HTTP/1.0" if $test_mode eq "http/1.0";

      $peersock->syswrite( "$protocol 200 OK$CRLF" . 
                           "Content-Length: " . length( $body ) . $CRLF .
                           "Connection: Keep-Alive$CRLF" .
                           $CRLF .
                           $body );

      # Wait for the server to finish its response
      wait_for { keys %wait < $waitcount };
   }

   $loop->remove( $http );
}

# foreach $test_mode doesn't quite work as expected
foreach (qw( pipeline no_pipeline http/1.0 )) {
   $test_mode = $_;

   do_uris(
      URI->new( "http://server/path/1" ) => sub {
         my ( $req ) = @_;
         is( $req->content, "GET /path/1 HTTP/1.1", "First of three pipeline for $test_mode" );
      },
      URI->new( "http://server/path/2" ) => sub {
         my ( $req ) = @_;
         is( $req->content, "GET /path/2 HTTP/1.1", "Second of three pipeline for $test_mode" );
      },
      URI->new( "http://server/path/3" ) => sub {
         my ( $req ) = @_;
         is( $req->content, "GET /path/3 HTTP/1.1", "Third of three pipeline for $test_mode" );
      },
   );
}

done_testing;
