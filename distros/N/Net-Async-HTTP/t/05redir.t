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

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

{
   my $redir_response;
   my $location;

   my $response;

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

   my $future = $http->do_request(
      uri => URI->new( "http://host0/doc" ),

      timeout => 10,

      on_response => sub { $response = $_[0] },
      on_redirect => sub { ( $redir_response, $location ) = @_ },
      on_error    => sub { die "Test died early - $_[0]" },
   );

   ok( defined $future, '$future defined for redirect' );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   my $req_firstline = $1;

   is( $req_firstline, "GET /doc HTTP/1.1", 'First line for request' );

   # Trim headers
   $request_stream =~ s/^(.*)$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 301 Moved Permanently$CRLF" .
                        "Content-Length: 0$CRLF" .
                        "Location: http://host0/get_doc?name=doc$CRLF" .
                        "Connection: Keep-Alive$CRLF" .
                        "$CRLF" );

   wait_for { defined $location };

   is( $location, "http://host0/get_doc?name=doc", 'Redirect happens' );

   ok( !$future->is_ready, '$future is not yet ready after redirect' );

   $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   $req_firstline = $1;

   is( $req_firstline, "GET /get_doc?name=doc HTTP/1.1", 'First line for redirected request' );

   # Trim headers
   $request_stream =~ s/^(.*)$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 8$CRLF".
                        "Content-Type: text/plain$CRLF" .
                        "Connection: Keep-Alive$CRLF" .
                        "$CRLF" .
                        "Document" );

   wait_for { defined $response };

   is( $response->content_type, "text/plain", 'Content type of final response' );
   is( $response->content, "Document", 'Content of final response' );

   isa_ok( $response->previous, "HTTP::Response", '$response->previous' );

   my $previous = $response->previous;
   isa_ok( $previous->request->uri, "URI", 'Previous request URI is a URI' );
   is( $previous->request->uri, "http://host0/doc", 'Previous request URI string' );

   ok( $future->is_ready, '$future is now ready for final response' );
   identical( scalar $future->get, $response, '$future->get yields final response' );
}

{
   my $redir_response;
   my $location;

   my $response;

   my $peersock;
   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      $args{host}    eq "host1" or die "Expected $args{host} eq host1";
      $args{service} eq "80"    or die "Expected $args{service} eq 80";

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   $http->do_request(
      uri => URI->new( "http://host1/somedir" ),

      timeout => 10,

      on_response => sub { $response = $_[0] },
      on_redirect => sub { ( $redir_response, $location ) = @_ },
      on_error    => sub { die "Test died early - $_[0]" },
   );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   my $req_firstline = $1;

   is( $req_firstline, "GET /somedir HTTP/1.1", 'First line for request for local redirect' );

   # Trim headers
   $request_stream =~ s/^(.*)$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 301 Moved Permanently$CRLF" .
                        "Content-Length: 0$CRLF" .
                        "Location: /somedir/$CRLF" .
                        "$CRLF" );

   undef $location;
   wait_for { defined $location };

   is( $location, "http://host1/somedir/", 'Local redirect happens' );

   $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   $req_firstline = $1;

   is( $req_firstline, "GET /somedir/ HTTP/1.1", 'First line for locally redirected request' );

   # Trim headers
   $request_stream =~ s/^(.*)$CRLF$CRLF//s;

   $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                        "Content-Length: 9$CRLF".
                        "Content-Type: text/plain$CRLF" .
                        "$CRLF" .
                        "Directory" );

   undef $response;
   wait_for { defined $response };

   is( $response->content_type, "text/plain", 'Content type of final response to local redirect' );
   is( $response->content, "Directory", 'Content of final response to local redirect' );
}

# 304 Not Modified should not redirect (RT98093)
{
   my $peersock;
   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      $args{host}    eq "host2" or die "Expected $args{host} eq host2";

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   my $f = $http->do_request(
      uri => URI->new( "http://host2/unmod" ),

      on_redirect => sub { die "Should not be redirected" },
   );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( "HTTP/1.1 304 Not Modified$CRLF" .
                        $CRLF ); # 304 has no body

   wait_for { $f->is_ready };

   my $response = $f->get;
   is( $response->code, 304, 'HTTP 304 response not redirected' );
}

# Methods other than GET and HEAD should not redirect
{
   my $peersock;
   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      $args{host}    eq "host3" or die "Expected $args{host} eq host3";

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   my $f = $http->do_request(
      method => "PUT",
      uri    => URI->new( "http://host3/somewhere" ),
      content => "new content",
      content_type => "text/plain",

      on_redirect => sub { die "Should not be redirected" },
   );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( "HTTP/1.1 301 Moved Permanently$CRLF" .
                        "Content-Length: 0$CRLF" .
                        "Location: /somewhere/else$CRLF" .
                        $CRLF );

   wait_for { $f->is_ready };

   my $response = $f->get;
   is( $response->code, 301, 'POST request not redirected' );
}

done_testing;
