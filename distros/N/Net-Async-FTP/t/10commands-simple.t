#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Net::Async::FTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $ftp = Net::Async::FTP->new( handle => $S1 );

$loop->add( $ftp );

# We won't log in.. our pseudo-server will just accept any command

# ->delete and ->rename by futures
{
   my $f;

   $f = $ftp->dele(
      path => "path/to/file",
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "DELE path/to/file$CRLF", 'DELE command' );

   $S2->syswrite( "250 Completed$CRLF" );

   wait_for { $f->is_ready };
   $f->get;

   pass( 'Done after 250 for ->dele' );

   $f = $ftp->rename(
      oldpath => "some/oldname",
      newpath => "some/newname",
   );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "RNFR some/oldname$CRLF", 'RNFR command' );

   $S2->syswrite( "350 More information required$CRLF" );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "RNTO some/newname$CRLF", 'RNTO command' );

   $S2->syswrite( "250 Completed$CRLF" );

   wait_for { $f->is_ready };
   $f->get;

   pass( 'Done after 250 for ->rename' );
}

# Legacy callbacks
{
   my $done;

   $ftp->dele(
      path => "path/to/file",
      on_done => sub { $done = 1 },
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "DELE path/to/file$CRLF", 'DELE command' );

   $S2->syswrite( "250 Completed$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 250' );

   $done = 0;

   $ftp->rename(
      oldpath => "some/oldname",
      newpath => "some/newname",
      on_done => sub { $done = 1 },
   );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "RNFR some/oldname$CRLF", 'RNFR command' );

   $S2->syswrite( "350 More information required$CRLF" );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "RNTO some/newname$CRLF", 'RNTO command' );

   $S2->syswrite( "250 Completed$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 250' );
}

done_testing;
