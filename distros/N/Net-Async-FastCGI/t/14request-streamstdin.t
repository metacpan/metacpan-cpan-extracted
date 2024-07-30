#!/usr/bin/perl

use v5.14;
use warnings;

use lib 't/lib';

use Test2::V0;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::FastCGI;

use TestFCGI;

my $CRLF = "\x0d\x0a";

my $request;

my ( $S, $selfaddr ) = make_server_sock;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $received_stdin = "";

my $fcgi = Net::Async::FastCGI->new(
   handle => $S,
   stream_stdin => 1,
   on_request => sub {
      $request = $_[1];

      $request->set_on_stdin_read( sub {
         my ( $request, $buffref, $eof ) = @_;

         $received_stdin = $$buffref;
         $$buffref = "";

         return 0;
      } );
   },
);

$loop->add( $fcgi );

my $C = connect_client_sock( $selfaddr );

{
   $C->syswrite(
      # Begin
      fcgi_trans( type => 1, id => 1, data => "\0\1\0\0\0\0\0\0" ) .
      # Parameters
      fcgi_trans( type => 4, id => 1, data =>
         fcgi_keyval( REQUEST_METHOD  => "GET" ) .
         fcgi_keyval( SCRIPT_NAME     => "/cgi-bin/foo.fcgi" ) .
         fcgi_keyval( PATH_INFO       => "/another/path" ) .
         fcgi_keyval( QUERY_STRING    => "foo=bar" ) .
         fcgi_keyval( SERVER_PROTOCOL => "HTTP/1.1" )
      ) .
      # End of parameters
      fcgi_trans( type => 4, id => 1, data => "" )
      # no STDIN yet
   );

   wait_for { defined $request };

   is( $request->params,
       {
          REQUEST_METHOD  => "GET",
          SCRIPT_NAME     => "/cgi-bin/foo.fcgi",
          PATH_INFO       => "/another/path",
          QUERY_STRING    => "foo=bar",
          SERVER_PROTOCOL => "HTTP/1.1",
       },
       '$request has correct params' );

   $C->syswrite(
      # STDIN
      fcgi_trans( type => 5, id => 1, data => "Hello, FastCGI script$CRLF" . 
                                              "Here are several lines of data$CRLF" .
                                              "They should appear on STDIN$CRLF" )
   );

   wait_for { length $received_stdin };

   is( $received_stdin,
         "Hello, FastCGI script$CRLF" . 
         "Here are several lines of data$CRLF" .
         "They should appear on STDIN$CRLF",
      'Streaming request received stdin data via on_stdin_read' );

   $C->syswrite(
      # End of STDIN
      fcgi_trans( type => 5, id => 1, data => "" )
   );
}

$received_stdin = "";

# Early writing of STDIN data is still captured
{
   $C->syswrite(
      # Begin
      fcgi_trans( type => 1, id => 1, data => "\0\1\0\0\0\0\0\0" ) .
      # Parameters
      fcgi_trans( type => 4, id => 1, data =>
         fcgi_keyval( REQUEST_METHOD  => "GET" ) .
         fcgi_keyval( SCRIPT_NAME     => "/cgi-bin/foo.fcgi" ) .
         fcgi_keyval( PATH_INFO       => "/another/path" ) .
         fcgi_keyval( QUERY_STRING    => "foo=bar" ) .
         fcgi_keyval( SERVER_PROTOCOL => "HTTP/1.1" )
      ) .
      # STDIN - early
      fcgi_trans( type => 5, id => 1, data => "Hello, FastCGI script$CRLF" ) .
      # End of parameters
      fcgi_trans( type => 4, id => 1, data => "" )
   );

   wait_for { defined $request };

   wait_for { length $received_stdin };

   is( $received_stdin,
         "Hello, FastCGI script$CRLF",
      'Streaming request received early stdin data' );
}

$received_stdin = "";

$fcgi->configure(
   on_request => sub {
      $request = $_[1];

      $request->set_on_stdin_read( sub {
         my ( $request, $buffref, $eof ) = @_;

         # eat just one byte
         $received_stdin .= substr $$buffref, 0, 1, "";

         return 1;
      } );
   },
);

{
   $C->syswrite(
      # Begin
      fcgi_trans( type => 1, id => 1, data => "\0\1\0\0\0\0\0\0" ) .
      # Parameters
      fcgi_trans( type => 4, id => 1, data =>
         fcgi_keyval( REQUEST_METHOD  => "GET" ) .
         fcgi_keyval( SCRIPT_NAME     => "/cgi-bin/foo.fcgi" ) .
         fcgi_keyval( PATH_INFO       => "/another/path" ) .
         fcgi_keyval( QUERY_STRING    => "foo=bar" ) .
         fcgi_keyval( SERVER_PROTOCOL => "HTTP/1.1" )
      ) .
      # End of parameters
      fcgi_trans( type => 4, id => 1, data => "" )
   );

   $C->syswrite(
      # STDIN
      fcgi_trans( type => 5, id => 1, data => "ABCDEFGHIJ" )
   );

   wait_for { length $received_stdin >= 10 };

   is( $received_stdin, "ABCDEFGHIJ",
      'Streaming stdin data eventually received by one-byte-at-once handler' );
}

done_testing;
