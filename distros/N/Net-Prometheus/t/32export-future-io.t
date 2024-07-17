#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Socket qw( SOCK_STREAM $CRLF );
use Net::Prometheus;

eval { require Future::IO::Impl::UV; Future::IO::Impl::UV->VERSION( '0.03' ) } or
   plan skip_all => "Future::IO::Impl::UV 0.03 is not available";

my $client = Net::Prometheus->new;

my $listensock;
my $export_f = $client->export_to_Future_IO(
   port => 0,
   on_listen => sub { $listensock = $_[0] },
);

ok( defined $listensock, '$listensock is defined after ->export_to_Future_IO' );

my $fh = IO::Socket::INET->new(
   PeerHost => $listensock->sockhost,
   PeerPort => $listensock->sockport,
   Type     => SOCK_STREAM,
) or die "Cannot connect() - $@";

# TODO: Some sort of minimal Future::IO-based HTTP client would be lovely here

Future::IO->syswrite( $fh, "GET /metrics HTTP/1.1$CRLF$CRLF" )->get;

my $response = "";
$response .= Future::IO->sysread( $fh, 8192 )->get until $response =~ m/$CRLF$CRLF/;

$response =~ s/^(.*$CRLF$CRLF)//s; my $header = $1;

like( $header, qr(^HTTP/1.0 200 OK$CRLF), 'Response header first-line' );

# TODO: Maybe hunt in $response for some metrics?

done_testing;
