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

# ->stor future
{
   my $f = $ftp->stor(
      path => "put/this",
      data => "Some new content for the server\n",
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "PASV$CRLF", 'PASV preceeds STOR' );

   my $D = accept_dataconn( $S2 );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STOR put/this$CRLF", 'STOR command' );

   $S2->syswrite( "150 File status okay; about to open data connection$CRLF" );

   my $data_stream = "";
   # TODO: Needs to wait for stream EOF but not sure how to do that
   wait_for_stream { $data_stream =~ m/\n/ } $D => $data_stream;
   $D->close;

   is( $data_stream, "Some new content for the server\n", '$data_stream after EOF' );

   $S2->syswrite( "226 Closing data connection$CRLF" );

   wait_for { $f->is_ready };

   $f->get;
   pass( 'Future done after 226' );
}

# Legacy callbacks
{
   my $done;

   $ftp->stor(
      path => "put/this",
      data => "Some new content for the server\n",
      on_stored => sub { $done = 1; },
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "PASV$CRLF", 'PASV preceeds STOR' );

   my $D = accept_dataconn( $S2 );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STOR put/this$CRLF", 'STOR command' );

   $S2->syswrite( "150 File status okay; about to open data connection$CRLF" );

   my $data_stream = "";
   # TODO: Needs to wait for stream EOF but not sure how to do that
   wait_for_stream { $data_stream =~ m/\n/ } $D => $data_stream;
   $D->close;

   is( $data_stream, "Some new content for the server\n", '$data_stream after EOF' );

   $S2->syswrite( "226 Closing data connection$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 226' );
}

done_testing;
