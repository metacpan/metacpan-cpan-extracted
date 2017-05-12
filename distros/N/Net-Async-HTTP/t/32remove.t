#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new;
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

my $f = $http->do_request(
   request => HTTP::Request->new( GET => "/", [ Host => $host ] ),
   host    => $host,
);

my $request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

$request_stream = "";

$peersock->print( "HTTP/1.1 200 OK$CRLF" .
                  "Content-Length: 0$CRLF" .
                  $CRLF );

wait_for { $f->is_ready };

# gut-wrenching
my $conn = $http->{connections}{"$host:80"}[0];
ok( $conn, 'Found a connection' );

# 1 internally in the $http, 2 in IO::Async internals, 1 here
is_refcount( $conn, 4, 'Connection has 4 references' );

$loop->remove( $http );
undef $http;

is_oneref( $conn, 'Connection has 1 reference remaining at EOF' );

done_testing;
