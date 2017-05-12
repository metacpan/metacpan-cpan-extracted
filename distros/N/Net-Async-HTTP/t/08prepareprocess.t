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

my $http = TestingHTTP->new(
   user_agent => "", # Don't put one in request headers
);

ok( defined $http, 'defined $http' );
isa_ok( $http, "Net::Async::HTTP", '$http isa Net::Async::HTTP' );

$loop->add( $http );

my $peersock;

no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;

   $args{host}    eq "some.server" or die "Expected $args{host} eq some.server";
   $args{service} eq "80"          or die "Expected $args{service} eq 80";

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->new->done( $self );
};

my $response;

$http->do_request(
   uri => URI->new( "http://some.server/here" ),

   on_response => sub { $response = $_[0] },
   on_error    => sub { die "Test died early - $_[0]" },
);

my $request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

$request_stream =~ s/^(.*)$CRLF//;
my $req_firstline = $1;

is( $req_firstline, "GET /here HTTP/1.1", 'First line for request' );

# Trim headers
$request_stream =~ s/^(.*)$CRLF$CRLF//s;
my %req_headers = map { m/^(.*?):\s+(.*)$/g } split( m/$CRLF/, $1 );

is( $req_headers{"X-Request-Foo"}, "Bar", 'Request sets X-Request-Foo header' );

$peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                     "Content-Length: 7$CRLF".
                     "Content-Type: text/plain$CRLF" .
                     "X-Response-Foo: Splot$CRLF" .
                     "$CRLF" .
                     "Blahbla" );

my $response_header_X;

undef $response;
wait_for { defined $response };

is( $response_header_X, "Splot", 'Response processed' );

done_testing;

package TestingHTTP;
use base qw( Net::Async::HTTP );

sub prepare_request
{
   my $self = shift;
   my ( $request ) = @_;
   $self->SUPER::prepare_request( $request );

   $request->header( "X-Request-Foo" => "Bar" );
}

sub process_response
{
   my $self = shift;
   my ( $response ) = @_;
   $self->SUPER::process_response( $response );

   $response_header_X = $response->header( "X-Response-Foo" );
}
