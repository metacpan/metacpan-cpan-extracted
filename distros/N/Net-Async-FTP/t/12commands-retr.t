#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Net::Async::FTP;
use t::TestFTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $ftp = Net::Async::FTP->new( handle => $S1 );

$loop->add( $ftp );

# We won't log in.. our pseudo-server will just accept any command

# ->retr future
{
   my $f = $ftp->retr(
      path => "get/this",
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "PASV$CRLF", 'PASV preceeds RETR' );

   my $D = accept_dataconn( $S2 );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "RETR get/this$CRLF", 'RETR command' );

   $D->syswrite( "Here is my file content\n" );
   $D->close;

   $S2->syswrite( "226 Closing data connection$CRLF" );

   wait_for { $f->is_ready };

   my $data = $f->get;
   is( $data, "Here is my file content\n", '$data after 226' );
}

# Legacy callbacks
{
   my $done;
   my $data;

   $ftp->retr(
      path => "get/this",
      on_data => sub { $data = shift; $done = 1; },
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "PASV$CRLF", 'PASV preceeds RETR' );

   my $D = accept_dataconn( $S2 );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "RETR get/this$CRLF", 'RETR command' );

   $D->syswrite( "Here is my file content\n" );
   $D->close;

   $S2->syswrite( "226 Closing data connection$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 226' );
   is( $data, "Here is my file content\n", '$data after 226' );
}

done_testing;
