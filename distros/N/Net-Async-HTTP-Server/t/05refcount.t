#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000147;

use IO::Async::Test;
use IO::Async::Loop;

use IO::Async::Stream;

use Net::Async::HTTP::Server;

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $req;
my $server = Net::Async::HTTP::Server->new(
   on_request => sub {
      my $self = shift;
      ( $req ) = @_;
   },
);

$loop->add( $server );

sub connect_client
{
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( undef, "stream" );
   $server->on_accept( Net::Async::HTTP::Server::Protocol->new( handle => $S2 ) );
   return $S1;
}

my $client = connect_client;
$client->write(
   "GET /path?var=value HTTP/1.1$CRLF" .
   "$CRLF"
);

wait_for { defined $req };

is_oneref( $req, '$req has one reference' );

done_testing;
