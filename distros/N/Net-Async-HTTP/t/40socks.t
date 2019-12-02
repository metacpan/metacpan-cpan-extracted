#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

BEGIN {
   eval {
      require Net::Async::SOCKS;
      Net::Async::SOCKS->VERSION( '0.003' );
   } or plan skip_all => "No Net::Async::SOCKS";
}

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
   SOCKS_host => "socks.host",
   SOCKS_port => "1234",
);

$loop->add( $http );

my %connect_args;
my $connect_f;

no warnings 'redefine';
local *IO::Async::Loop::SOCKS_connect = sub {
   shift;
   ( %connect_args ) = @_;

   return $connect_f = Future->new;
};

my $f = $http->do_request(
   uri => URI->new( "http://remote-site-here/" ),
);

# Check that ->SOCKS_connect was invoked correctly
my $handle;
{
   wait_for { keys %connect_args };

   $handle = delete $connect_args{handle};
   delete @connect_args{qw( SSL on_error )};
   is_deeply( \%connect_args,
      {
         family   => 0,
         socktype => "stream",
         host     => "remote-site-here",
         service  => 80,
         is_proxy => '',

         SOCKS_host => "socks.host",
         SOCKS_port => 1234,
      },
      'SOCKS_connect invoked'
   );
}

# Set up a socket connection
my $peersock;
{
   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $handle->set_handle( $selfsock );

   $connect_f->done( $handle );
}

# Handle request/response cycle
{
   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   is( $1, "GET / HTTP/1.1",
      'Received request firstline' );

   $request_stream =~ s/^(.*)$CRLF$CRLF//s;
   my %req_headers = map { m/^([^:]+):\s+(.*)$/g } split( m/$CRLF/, $1 );

   is_deeply( \%req_headers,
      {
         Host       => "remote-site-here",
         Connection => "keep-alive",
      },
      'Received request headers' );

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 0$CRLF" .
                        $CRLF );
}

my $response = wait_for_future( $f )->get;

is( $response->code, 200, '$response' );

done_testing;
