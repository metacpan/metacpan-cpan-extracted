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

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   $self->configure( write_len => 10 );

   return Future->new->done( $self );
};

{
   my @written;
   my $req_f = $http->do_request(
      request => HTTP::Request->new( PUT => "/content", [ Host => "somewhere" ] ),
      host => "somewhere",
      request_body => "X" x 100,

      on_body_write => sub { push @written, $_[0] },
   );

   defined $peersock or die "No peersock\n";

   # Wait for the client to send its request
   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;
   $request_stream =~ s/^(.*)$CRLF$CRLF//s;
   wait_for_stream { $request_stream =~ m/X{100}/ } $peersock => $request_stream;

   $peersock->syswrite( "HTTP/1.1 201 Created$CRLF" .
                        "Content-Length: 0$CRLF" .
                        "Connection: Keep-Alive$CRLF" .
                        $CRLF );

   wait_for { $req_f->is_ready };

   is_deeply( \@written,
              [ 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 ],
              'on_body_write invoked per body write call' );
}

done_testing;
