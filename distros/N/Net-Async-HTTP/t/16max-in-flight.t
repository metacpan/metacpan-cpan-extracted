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
   max_in_flight => 2
);
$loop->add( $http );

my $host = "host.example";

my $peersock;
no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;

   $args{host}    eq $host or die "Expected $args{host} eq $host";
   $args{service} eq "80"  or die "Expected $args{service} eq 80";

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->new->done( $self );
};

my @resp;
$http->do_request(
   request => HTTP::Request->new( GET => "/$_", [ Host => $host ] ),
   host    => $host,
   on_response => sub { push @resp, shift },
   on_error    => sub { die "Test died early - $_[-1]" },
) for 0 .. 3;

wait_for { $peersock };

# CHEATING
my $conn = $http->{connections}->{"$host:80"}->[0] or die "Unable to find connection object";
ref $conn eq "Net::Async::HTTP::Connection" or die "Unable to find connection object";

my $request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

ok( $request_stream =~ m[^GET /0 HTTP/1\.1$CRLF.*?$CRLF$CRLF$]s, 'Request stream contains first request only' );
$request_stream = "";

# CHEATING
is( scalar @{ $conn->{ready_queue} }, 3, '3 requests still queued' );

$peersock->print( "HTTP/1.1 200 OK$CRLF" .
                  "Content-Length: 0$CRLF" .
                  "$CRLF" );

wait_for { $resp[0] };
is( $resp[0]->code, 200, 'Request /0 responded OK' );

wait_for_stream { $request_stream =~ m/(?:.*$CRLF$CRLF){2}/s } $peersock => $request_stream;

ok( $request_stream =~ m[^GET /1 HTTP/1\.1$CRLF.*?${CRLF}${CRLF}GET /2 HTTP/1\.1$CRLF.*?${CRLF}${CRLF}$]s,
   'Request stream contains second and third requests after first response' );
$request_stream = "";

# CHEATING
is( scalar @{ $conn->{ready_queue} }, 1, '1 request still queued' );

$peersock->print( "HTTP/1.1 200 OK$CRLF" .
                  "Content-Length: 1$CRLF" .
                  "$CRLF" .
                  "A" );
$peersock->print( "HTTP/1.1 200 OK$CRLF" .
                  "Content-Length: 2$CRLF" .
                  "$CRLF" .
                  "AB" );

wait_for { $resp[2] };
is( $resp[1]->content, "A",  'Request /1 content' );
is( $resp[2]->content, "AB", 'Request /2 content' );

wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;
ok( $request_stream =~ m[^GET /3 HTTP/1\.1$CRLF.*?$CRLF$CRLF$]s, 'Request stream contains final request' );

$peersock->print( "HTTP/1.1 200 OK$CRLF" .
                  "Content-Length: 0$CRLF" .
                  "$CRLF" );

wait_for { $resp[3] };
is( $resp[3]->code, 200, 'Request /3 responded OK' );

done_testing;
