#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Stream;

use Net::Async::FTP;

BEGIN {
   # File::Listing tries to parse timestamps in the local timezone. To make
   # the tests repeatable, we'll force it to GMT
   $ENV{TZ} = "GMT";
}

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $ftp = Net::Async::FTP->new( handle => $S1 );

$loop->add( $ftp );

# We won't log in.. our pseudo-server will just accept any command

# ->stat future
{
   my $f = $ftp->stat(
      path => "path/to/file",
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STAT path/to/file$CRLF", 'STAT command' );

   $S2->syswrite( "211-Status of path/to/file$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          100 Feb  2  2005 path/to/file$CRLF" );
   $S2->syswrite( "211 End of status$CRLF" );

   wait_for { $f->is_ready };

   my @stats = $f->get;
   is_deeply( \@stats,
              [ '-rw-r--r--   1 user     user          100 Feb  2  2005 path/to/file' ],
              '@stats after 211' );
}

# ->stat_parsed future
{
   my $f;
   my @stats;

   $f = $ftp->stat_parsed(
      path => "path/to/file",
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STAT path/to/file$CRLF", 'STAT command parsed' );

   $S2->syswrite( "211-Status of path/to/file$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          100 Feb  2  2005 path/to/file$CRLF" );
   $S2->syswrite( "211 End of status$CRLF" );

   wait_for { $f->is_ready };

   @stats = $f->get;
   is_deeply( \@stats,
              [ { name  => "path/to/file", 
                  type  => "f",
                  size  => 100,
                  mtime => 1107302400,
                  mode  => 0100644 } ],
              '@stats after 211 parsed' );

   $f = $ftp->stat_parsed(
      path => "path/to",
   );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STAT path/to$CRLF", 'STAT command on dir parsed' );

   $S2->syswrite( "211-Status of path/to$CRLF" );
   $S2->syswrite( "211-drwxr-xr-x   2 user     user            0 Feb  1  2005 .$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          100 Feb  2  2005 file$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          200 Feb  3  2005 other$CRLF" );
   $S2->syswrite( "211 End of status$CRLF" );

   wait_for { $f->is_ready };

   @stats = $f->get;
   is_deeply( \@stats,
              [ { name  => ".", 
                  type  => "d",
                  size  => undef,
                  mtime => 1107216000,
                  mode  => 040755 },
                { name  => "file", 
                  type  => "f",
                  size  => 100,
                  mtime => 1107302400,
                  mode  => 0100644 },
                { name  => "other", 
                  type  => "f",
                  size  => 200,
                  mtime => 1107388800,
                  mode  => 0100644 } ],
              '@stats after 211 on dir parsed' );
}

# Legacy callbacks
{
   my $done;
   my @stats;

   $ftp->stat(
      path => "path/to/file",
      on_stat => sub { @stats = @_; $done = 1 },
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STAT path/to/file$CRLF", 'STAT command' );

   $S2->syswrite( "211-Status of path/to/file$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          100 Feb  2  2005 path/to/file$CRLF" );
   $S2->syswrite( "211 End of status$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 211' );
   is_deeply( \@stats,
              [ '-rw-r--r--   1 user     user          100 Feb  2  2005 path/to/file' ],
              '@stats after 211' );

   $done = 0;

   $ftp->stat(
      path => "path/to",
      on_stat => sub { @stats = @_; $done = 1 },
   );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STAT path/to$CRLF", 'STAT command on dir' );

   $S2->syswrite( "211-Status of path/to$CRLF" );
   $S2->syswrite( "211-drwxr-xr-x   2 user     user            0 Feb  1  2005 .$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          100 Feb  2  2005 file$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          200 Feb  3  2005 other$CRLF" );
   $S2->syswrite( "211 End of status$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 211 on dir' );
   is_deeply( \@stats,
              [ 'drwxr-xr-x   2 user     user            0 Feb  1  2005 .',
                '-rw-r--r--   1 user     user          100 Feb  2  2005 file',
                '-rw-r--r--   1 user     user          200 Feb  3  2005 other' ],
              '@stats after 211 on dir' );

   $done = 0;

   $ftp->stat_parsed(
      path => "path/to/file",
      on_stat => sub { @stats = @_; $done = 1 },
   );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STAT path/to/file$CRLF", 'STAT command parsed' );

   $S2->syswrite( "211-Status of path/to/file$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          100 Feb  2  2005 path/to/file$CRLF" );
   $S2->syswrite( "211 End of status$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 211 parsed' );
   is_deeply( \@stats,
              [ { name  => "path/to/file", 
                  type  => "f",
                  size  => 100,
                  mtime => 1107302400,
                  mode  => 0100644 } ],
              '@stats after 211 parsed' );

   $done = 0;

   $ftp->stat_parsed(
      path => "path/to",
      on_stat => sub { @stats = @_; $done = 1 },
   );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "STAT path/to$CRLF", 'STAT command on dir parsed' );

   $S2->syswrite( "211-Status of path/to$CRLF" );
   $S2->syswrite( "211-drwxr-xr-x   2 user     user            0 Feb  1  2005 .$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          100 Feb  2  2005 file$CRLF" );
   $S2->syswrite( "211--rw-r--r--   1 user     user          200 Feb  3  2005 other$CRLF" );
   $S2->syswrite( "211 End of status$CRLF" );

   wait_for { $done };

   is( $done, 1, '$done after 211 on dir parsed' );
   is_deeply( \@stats,
              [ { name  => ".", 
                  type  => "d",
                  size  => undef,
                  mtime => 1107216000,
                  mode  => 040755 },
                { name  => "file", 
                  type  => "f",
                  size  => 100,
                  mtime => 1107302400,
                  mode  => 0100644 },
                { name  => "other", 
                  type  => "f",
                  size  => 200,
                  mtime => 1107388800,
                  mode  => 0100644 } ],
              '@stats after 211 on dir parsed' );
}

done_testing;
