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

ok( defined $http, 'defined $http' );
isa_ok( $http, "Net::Async::HTTP", '$http isa Net::Async::HTTP' );

$loop->add( $http );

my $hostnum = 0;

sub do_test_req
{
   my $name = shift;
   my %args = @_;

   my $response;
   my $error;

   my $request = $args{req};
   my $host    = $args{no_host} ? $request->uri->host : "host$hostnum"; $hostnum++;

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

   my $future = $http->do_request(
      request => $request,
      ( $args{no_host} ? () : ( host => $host ) ),

      timeout => 10,

      on_response => sub { $response = $_[0] },
      on_error    => sub { $error    = $_[0] },
   );
   $future->on_fail( sub { $future->get } ) unless $args{expect_error};

   ok( defined $future, "\$future defined for $name" );

   wait_for { $peersock };

   # Wait for the client to send its request
   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $request_stream =~ s/^(.*)$CRLF//;
   my $req_firstline = $1;

   is( $req_firstline, $args{expect_req_firstline}, "First line for $name" );

   $request_stream =~ s/^(.*)$CRLF$CRLF//s;
   my %req_headers = map { m/^([^:]+):\s+(.*)$/g } split( m/$CRLF/, $1 );

   my $req_content;
   if( defined( my $len = $req_headers{'Content-Length'} ) ) {
      wait_for { length( $request_stream ) >= $len };

      $req_content = substr( $request_stream, 0, $len );
      substr( $request_stream, 0, $len ) = "";
   }

   my $expect_req_headers = $args{expect_req_headers};

   foreach my $header ( keys %$expect_req_headers ) {
      is( $req_headers{$header}, $expect_req_headers->{$header}, "Expected value for $header" );
   }

   if( defined $args{expect_req_content} ) {
      is( $req_content, $args{expect_req_content}, "Request content for $name" );
   }

   $peersock->syswrite( $args{response} );
   $peersock->close if $args{close_after_response};

   # Future shouldn't be ready yet
   ok( !$future->is_ready, "\$future is not ready before response given for $name" );

   # Wait for the server to finish its response
   wait_for { defined $response or defined $error };

   if( $args{expect_error} ) {
      ok( defined $error, "Expected error for $name" );
      return;
   }
   else {
      ok( !defined $error, "Failed to error for $name" );
      if( defined $error ) {
         diag( "Got error $error" );
      }
   }

   identical( $response->request, $request, "\$response->request is \$request for $name" );

   ok( $future->is_ready, "\$future is now ready after response given for $name" );
   identical( scalar $future->get, $response, "\$future->get yields \$response for $name" );

   if( exists $args{expect_res_code} ) {
      is( $response->code, $args{expect_res_code}, "Result code for $name" );
   }

   if( exists $args{expect_res_content} ) {
      is( $response->content, $args{expect_res_content}, "Result content for $name" );
   }

   if( exists $args{expect_res_headers} ) {
      my %h = map { $_ => $response->header( $_ ) } $response->header_field_names;

      is_deeply( \%h, $args{expect_res_headers}, "Result headers for $name" );
   }
}

my $req;

$req = HTTP::Request->new( HEAD => "/some/path", [ Host => "myhost" ] );

do_test_req( "simple HEAD",
   req => $req,

   expect_req_firstline => "HEAD /some/path HTTP/1.1",
   expect_req_headers => {
      Host => "myhost",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Length: 13$CRLF" . 
               "Content-Type: text/plain$CRLF" .
               "Connection: keep-alive$CRLF" .
               $CRLF,

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Length' => 13,
      'Content-Type'   => "text/plain",
      'Connection'     => "keep-alive",
   },
   expect_res_content => "",
);

$req = HTTP::Request->new( GET => "/some/path", [ Host => "myhost" ] );

do_test_req( "simple GET",
   req => $req,
   host => "myhost",

   expect_req_firstline => "GET /some/path HTTP/1.1",
   expect_req_headers => {
      Host => "myhost",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Length: 13$CRLF" . 
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               $CRLF . 
               "Hello, world!",

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Length' => 13,
      'Content-Type'   => "text/plain",
      'Connection'     => "Keep-Alive",
   },
   expect_res_content => "Hello, world!",
);

$req = HTTP::Request->new( GET => "http://myhost/some/path" );

do_test_req( "GET to full URL",
   req => $req,
   host => "myhost",

   expect_req_firstline => "GET /some/path HTTP/1.1",
   expect_req_headers => {
      Host => "myhost",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Length: 13$CRLF" . 
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               $CRLF . 
               "Hello, world!",

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Length' => 13,
      'Content-Type'   => "text/plain",
      'Connection'     => "Keep-Alive",
   },
   expect_res_content => "Hello, world!",
);

$req = HTTP::Request->new( GET => "/empty", [ Host => "myhost" ] );

do_test_req( "GET with empty body",
   req => $req,
   host => "myhost",

   expect_req_firstline => "GET /empty HTTP/1.1",
   expect_req_headers => {
      Host => "myhost",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Length: 0$CRLF" . 
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               $CRLF,

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Length' => 0,
      'Content-Type'   => "text/plain",
      'Connection'     => "Keep-Alive",
   },
   expect_res_content => "",
);

$req = HTTP::Request->new( GET => "/" );

do_test_req( "GET with no response headers",
   req => $req,
   host => "myhost",

   expect_req_firstline => "GET / HTTP/1.1",
   expect_req_headers => {
      Host => "myhost",
   },

   response => "HTTP/1.0 200 OK$CRLF".
               $CRLF .
               "Your data here",
   close_after_response => 1,

   expect_res_code => 200,
   expect_req_headers => {},
   expect_res_content => "Your data here",
);

$req = HTTP::Request->new( GET => "/somethingmissing", [ Host => "somewhere" ] );

do_test_req( "GET not found",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "GET /somethingmissing HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
   },

   response => "HTTP/1.1 404 Not Found$CRLF" . 
               "Content-Length: 0$CRLF" .
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               $CRLF,

   expect_res_code    => 404,
   expect_res_headers => {
      'Content-Length' => 0,
      'Content-Type'   => "text/plain",
      'Connection'     => "Keep-Alive",
   },
   expect_res_content => "",
);

$req = HTTP::Request->new( GET => "/stream", [ Host => "somewhere" ] );

do_test_req( "GET chunks",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "GET /stream HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Length: 13$CRLF" .
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               "Transfer-Encoding: chunked$CRLF" .
               $CRLF .
               "7$CRLF" . "Hello, " . $CRLF .
               # Handle trailing whitespace on chunk size
               "6 $CRLF" . "world!" . $CRLF .
               "0$CRLF" .
               "$CRLF",

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Length' => 13,
      'Content-Type'   => "text/plain",
      'Connection'     => "Keep-Alive",
      'Transfer-Encoding' => "chunked",
   },
   expect_res_content => "Hello, world!",
);

do_test_req( "GET chunks LWS stripping",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "GET /stream HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Length: 13$CRLF" .
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               "Transfer-Encoding:   chunked  $CRLF" .
               $CRLF .
               "7$CRLF" . "Hello, " . $CRLF .
               "6$CRLF" . "world!" . $CRLF .
               "0$CRLF" .
               "$CRLF",

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Length' => 13,
      'Content-Type'   => "text/plain",
      'Connection'     => "Keep-Alive",
      'Transfer-Encoding' => "chunked",
   },
   expect_res_content => "Hello, world!",
);

do_test_req( "GET chunks corrupted",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "GET /stream HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
   },

   response => "HTTP/1.1 500 Internal Server Error$CRLF" . 
               "Content-Length: 21$CRLF" .
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               "Transfer-Encoding: chunked$CRLF" .
               $CRLF .
               "Internal Server Error" . $CRLF, # no chunk header
   close_after_response => 1,

   expect_error => 1,
);

$req = HTTP::Request->new( GET => "/untileof", [ Host => "somewhere" ] );

do_test_req( "GET unspecified length",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "GET /untileof HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Type: text/plain$CRLF" .
               "Connection: close$CRLF" .
               $CRLF .
               "Some more content here",
   close_after_response => 1,

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Type'   => "text/plain",
      'Connection'     => "close",
   },
   expect_res_content => "Some more content here",
);

do_test_req( "GET unspecified length LWS stripping",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "GET /untileof HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
   },

   response => "HTTP/1.1 200 OK$CRLF" . 
               "Content-Type: text/plain$CRLF" .
               "Connection:   close  $CRLF" .
               $CRLF .
               "Some more content here",
   close_after_response => 1,

   expect_res_code    => 200,
   expect_res_headers => {
      'Content-Type'   => "text/plain",
      'Connection'     => "close",
   },
   expect_res_content => "Some more content here",
);

$req = HTTP::Request->new( POST => "/handler", [ Host => "somewhere" ], "New content" );

do_test_req( "simple POST",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "POST /handler HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
      'Content-Length' => 11,
   },
   expect_req_content => "New content",

   response => "HTTP/1.1 201 Created$CRLF" . 
               "Content-Length: 11$CRLF" .
               "Content-Type: text/plain$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               $CRLF .
               "New content",

   expect_res_code    => 201,
   expect_res_headers => {
      'Content-Length' => 11,
      'Content-Type'   => "text/plain",
      'Connection'     => "Keep-Alive",
   },
   expect_res_content => "New content",
);

$req = HTTP::Request->new( PUT => "/handler", [ Host => "somewhere" ], "New content" );

do_test_req( "simple PUT",
   req => $req,
   host => "somewhere",

   expect_req_firstline => "PUT /handler HTTP/1.1",
   expect_req_headers => {
      Host => "somewhere",
      'Content-Length' => 11,
   },
   expect_req_content => "New content",

   response => "HTTP/1.1 201 Created$CRLF" . 
               "Content-Length: 0$CRLF" .
               "Connection: Keep-Alive$CRLF" .
               $CRLF,

   expect_res_code    => 201,
   expect_res_headers => {
      'Content-Length' => 0,
      'Connection'     => "Keep-Alive",
   },
);

$req = HTTP::Request->new( GET => "http://somehost/with/path" );

do_test_req( "request-implied host",
   req => $req,
   no_host => 1,

   expect_req_firstline => "GET /with/path HTTP/1.1",
   expect_req_headers => {
      Host => "somehost",
   },

   response => "HTTP/1.1 200 OK$CRLF" .
               "Content-Length: 2$CRLF" .
               "Content-Type: text/plain$CRLF" .
               $CRLF .
               "OK",

   expect_res_code => 200,
);

$req = HTTP::Request->new( GET => "http://user:pass\@somehost2/with/secret" );

do_test_req( "request-implied authentication",
   req => $req,
   no_host => 1,

   expect_req_firstline => "GET /with/secret HTTP/1.1",
   expect_req_headers => {
      Host => "somehost2",
      Authorization => "Basic dXNlcjpwYXNz", # determined using 'wget'
   },

   response => "HTTP/1.1 200 OK$CRLF" .
               "Content-Length: 4$CRLF" .
               "Content-Type: text/plain$CRLF" .
               $CRLF .
               "Booo",

   expect_res_code => 200,
);

$req = HTTP::Request->new( GET => "/", [ Host => "myhost" ] );

do_test_req( "Non-HTTP response",
   req  => $req,
   host => "myhost",

   expect_req_firstline => "GET / HTTP/1.1",
   expect_req_headers => {
      Host => "myhost",
   },

   response => "Some other protocol, sorry\n",

   expect_error => 1,
);

done_testing;
