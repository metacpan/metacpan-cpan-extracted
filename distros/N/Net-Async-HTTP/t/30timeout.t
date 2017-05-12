#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

use Errno qw( EAGAIN );

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new();

$loop->add( $http );

my $peersock;

no warnings 'redefine';
my $latest_connection;
local *IO::Async::Handle::connect = sub {
   $latest_connection = my $self = shift;

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->new->done( $self );
};

{
   my $errcount;
   my $error;

   my $future = $http->do_request(
      uri => URI->new( "http://my.server/doc" ),

      timeout => 0.1, # Really quick for testing

      on_response => sub { die "Test died early - got a response but shouldn't have" },
      on_error    => sub { $errcount++; $error = $_[0] },
   );

   is_refcount( $http, 2, '$http refcount 2 after ->do_request with timeout' );

   wait_for { defined $error };

   is( $error, "Timed out", 'Received timeout error' );
   is( $errcount, 1, 'on_error invoked once' );

   ok( $future->is_ready, '$future is ready after timeout' );
   is( scalar $future->failure, "Timed out", '$future->failure after timeout' );
   is( ( $future->failure )[1], "timeout", '$future->failure [1] is timeout' );

   is_refcount( $http, 2, '$http refcount 2 after ->do_request with timeout fails' );
}

{
   my $errcount;
   my $error;

   my $future = $http->do_request(
      uri => URI->new( "http://my.server/redir" ),

      timeout => 0.1, # Really quick for testing

      on_response => sub { die "Test died early - got a response but shouldn't have" },
      on_error    => sub { $errcount++; $error = $_[0] },
   );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;

   $peersock->syswrite( "HTTP/1.1 301 Moved Permanently$CRLF" .
                        "Content-Length: 0$CRLF" .
                        "Location: http://my.server/get_doc?name=doc$CRLF" .
                        "Connection: Keep-Alive$CRLF" .
                        "$CRLF" );

   wait_for { defined $error };

   is( $error, "Timed out", 'Received timeout error from redirect' );
   is( $errcount, 1, 'on_error invoked once from redirect' );

   ok( $future->is_ready, '$future is ready after timeout' );
   is( scalar $future->failure, "Timed out", '$future->failure after timeout' );
   is( ( $future->failure )[1], "timeout", '$future->failure [1] is timeout' );
}

{
   my $error;
   my $errcount;

   $http->do_request(
      uri => URI->new( "http://my.server/first" ),

      timeout => 0.1, # Really quick for testing

      on_response => sub { die "Test died early - got a response but shouldn't have" },
      on_error    => sub { $errcount++; $error = $_[0] },
   );

   my $error2;
   my $errcount2;

   $http->do_request(
      uri => URI->new( "http://my.server/second" ),

      timeout => 0.3,

      on_response => sub { die "Test died early - got a response but shouldn't have" },
      on_error    => sub { $errcount2++; $error2 = $_[0] },
   );

   wait_for { defined $error };
   is( $error, "Timed out", 'Received timeout error from pipeline' );
   is( $errcount, 1, 'on_error invoked once from pipeline' );

   wait_for { defined $error2 };
   is( $error2, "Timed out", 'Received timeout error from pipeline(2)' );
   is( $errcount2, 1, 'on_error invoked once from pipeline(2)' );
}

# Stall during write
{
   my $future = $http->do_request(
      uri => URI->new( "http://stalling.server/write" ),

      stall_timeout => 0.1,
   );

   # Much hackery for unit-testing purposes
   $latest_connection->configure(
      writer => sub { $! = EAGAIN; return undef },
   );

   wait_for { $future->is_ready };
   is( scalar $future->failure, "Stalled while writing request", '$future->failure for stall during write' );
   is( ( $future->failure )[1], "stall_timeout", '$future->failure [1] is stall_timeout' );
}

# Stall during header read
{
   my $future = $http->do_request(
      uri => URI->new( "http://stalling.server/header" ),

      stall_timeout => 0.1,
   );

   # Don't write anything

   wait_for { $future->is_ready };
   is( scalar $future->failure, "Stalled while waiting for response", '$future->failure for stall during response header' );
   is( ( $future->failure )[1], "stall_timeout", '$future->failure [1] is stall_timeout' );
}

# Stall during header read
{
   my $future = $http->do_request(
      uri => URI->new( "http://stalling.server/read" ),

      stall_timeout => 0.1,
   );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 100$CRLF" ); # unfinished

   wait_for { $future->is_ready };
   is( scalar $future->failure, "Stalled while receiving response header", '$future->failure for stall during response header' );
   is( ( $future->failure )[1], "stall_timeout", '$future->failure [1] is stall_timeout' );
}

# Stall during body read
{
   my $future = $http->do_request(
      uri => URI->new( "http://stalling.server/read" ),

      stall_timeout => 0.1,
   );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 100$CRLF" .
                        $CRLF );
   $peersock->syswrite( "some of the content" ); # unfinished

   wait_for { $future->is_ready };
   is( scalar $future->failure, "Stalled while receiving body", '$future->failure for stall during response body' );
   is( ( $future->failure )[1], "stall_timeout", '$future->failure [1] is stall_timeout' );
}

$loop->remove( $http );

is_oneref( $http, '$http has refcount 1 before EOF' );

done_testing;
