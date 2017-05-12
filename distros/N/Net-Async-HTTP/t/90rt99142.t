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
   max_connections_per_host => 2,
);

$loop->add( $http );

{
   my @pending;
   no warnings 'redefine';
   *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;
      $args{host} eq "localhost" or die "Cannot fake connect - expected host 'localhost'";
      $args{service} eq "5000"   or die "Cannot fake connect - expected service '5000'";

      push @pending, [ $self, my $f = $loop->new_future ];
      return $f;
   };

   sub await_connection
   {
      wait_for { scalar @pending };

      return @{ shift @pending };
   }
}

# Make a first connection
my $req_f1 = $http->GET( "http://localhost:5000/1" );
my $peersock;
{
   my ( $conn, $conn_f ) = await_connection;

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $conn->set_handle( $selfsock );

   $conn_f->done( $conn );
}

# Before the first is ready, make a second one
my $req_f2 = $http->GET( "http://localhost:5000/2" );
my ( $conn2, $conn_f2 ) = await_connection;
ok( $conn_f2, 'Second connection request is pending' );

# Gutwrenching
is( scalar @{ $http->{connections}{"localhost:5000"} }, 2,
   '$http has two pending connections to localhost:5000' );

my $request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

like( $request_stream, qr(^GET /1), 'First request written' );
$request_stream = "";

# Respond with HTTP/1.1 so client knows it can pipeline
$peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                     "Content-Length: 0$CRLF" .
                     $CRLF );

wait_for { $req_f1->is_ready };
ok( $req_f1->is_done, '$req_f1 is done after first response' );

# At this point, req 2 should already be made down the socket
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

like( $request_stream, qr(^GET /2), 'Second request written down first socket' );

# And $conn_f2 should already be cancelled
ok( $conn_f2->is_cancelled, '$conn_f2 now cancelled' );

# Gutwrenching
is( scalar @{ $http->{connections}{"localhost:5000"} }, 1,
   '$http has only one connection to localhost:5000 at EOF' );

done_testing;
