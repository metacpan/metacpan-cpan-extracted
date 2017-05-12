#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

$SIG{PIPE} = "IGNORE";

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new;
$loop->add( $http );

my $peersock;
no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;

   $args{host}    eq "host0" or die "Expected $args{host} eq host0";
   $args{service} eq "80"    or die "Expected $args{service} eq 80";

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->new->done( $self );
};

my $body_sent;
my $resp;
$http->do_request(
   method => "PUT",
   uri    => URI->new( "http://host0/" ),
   expect_continue => 1,
   content_type => "text/plain",
   request_body => sub {
      return undef if $body_sent;
      $body_sent++;
      return "Here is the body content\n";
   },
   on_response => sub { $resp = shift },
   on_error    => sub { die "Test failed early - $_[-1]" },
);

wait_for { defined $peersock };

my $request_stream = "";
wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;
$request_stream =~ s/^(.*?$CRLF$CRLF)//s;
my $header = HTTP::Request->parse( $1 );

is( $header->header( "Expect" ), "100-continue", 'Received Expect header' );

ok( !$body_sent, 'request_body not yet invoked before 100 Continue' );

$peersock->print( "HTTP/1.1 100 Continue$CRLF" .
                  $CRLF );

wait_for { $body_sent };
ok( !defined $resp, '$resp not yet defined after 100 Continue' );

$peersock->print( "HTTP/1.1 201 Created$CRLF" .
                  "Content-Length: 0$CRLF" .
                  $CRLF );

wait_for { defined $resp };

ok( defined $resp, '$resp now defined after 201 Created' );
is( $resp->code, 201, '$resp->code is 201' );

done_testing;
