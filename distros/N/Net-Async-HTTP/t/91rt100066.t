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
);

$loop->add( $http );

my $peersock;
no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;
   $args{host} eq "localhost" or die "Cannot fake connect - expected host 'localhost'";
   $args{service} eq "5000"   or die "Cannot fake connect - expected service '5000'";

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->done( $self );
};

# Without on_error
{
   my $f1 = $http->GET( "http://localhost:5000/1" )
      ->on_done( sub { die "Oopsie" } );

   my $f2 = $http->GET( "http://localhost:5000/2" );

   wait_for { defined $peersock };

   my $request_stream = "";

   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;
   pass( "First request is made" );

   $request_stream =~ s/^.*$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 0$CRLF" .
                        $CRLF );

   my $e = eval { $loop->loop_once(0) for 1 .. 5; 1 } ? undef : $@;
   like( $e, qr/^Oopsie at \Q$0\E line \d+/,
      'Oopsie exception caught at loop toplevel' );

   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;
   pass( "Second request is made after first one dies at ->done" );

   $request_stream =~ s/^.*$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 0$CRLF" .
                        $CRLF );

   wait_for { $f2->is_ready };
   ok( !$f2->failure, '$f2 completes successfully' );
}

# With on_error
{
   my $error;
   $http->configure(
      on_error => sub { ( undef, $error ) = @_; },
   );

   my $f1 = $http->GET( "http://localhost:5000/1" )
      ->on_done( sub { die "Oopsie" } );

   my $f2 = $http->GET( "http://localhost:5000/2" );

   wait_for { defined $peersock };

   my $request_stream = "";

   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;
   pass( "First request is made" );

   $request_stream =~ s/^.*$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 0$CRLF" .
                        $CRLF );

   my $e = eval { $loop->loop_once(0) for 1 .. 5; 1 } ? undef : $@;
   ok( !defined $e, 'Loop toplevel does not catch exception' ) or
      diag( "Caught exception was: $e" );

   like( $error, qr/^Oopsie at \Q$0\E line \d+/,
      'Oopsie exception caught by on_error handler' );

   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;
   pass( "Second request is made after first one dies at ->done" );

   $request_stream =~ s/^.*$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 0$CRLF" .
                        $CRLF );

   wait_for { $f2->is_ready };
   ok( !$f2->failure, '$f2 completes successfully' );
}

done_testing;
