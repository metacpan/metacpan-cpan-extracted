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

my @on_error;

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers

   on_error => sub {
      my ( undef, @args ) = @_;

      push @on_error, [ @args ];
   },
);

$loop->add( $http );

# spurious trailing content
{
   my $peersock;
   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   my $f = $http->do_request(
      request => HTTP::Request->new( GET => "http://host/" ),
   );

   wait_for { $peersock };

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->print( "HTTP/1.1 200 OK$CRLF" .
                     "Content-Length: 11$CRLF" .
                     $CRLF .
                     "Hello world" .
                     "more stuff here" );

   wait_for { $f->is_ready };
   ok( !$f->failure, '$f is ready and does not fail' );
}

done_testing;
