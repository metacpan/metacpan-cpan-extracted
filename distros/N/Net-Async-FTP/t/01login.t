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

ok( defined $ftp, 'defined $ftp' );
isa_ok( $ftp, "Net::Async::FTP", '$ftp isa Net::Async::FTP' );

$loop->add( $ftp );

# ->login future
{
   my $f = $ftp->login(
      user => "testuser",
      pass => "secret",
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "USER testuser$CRLF", 'USER command' );

   $S2->syswrite( "331 Password Required$CRLF" );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "PASS secret$CRLF", 'PASS command' );

   $S2->syswrite( "230 Logged In$CRLF" );

   wait_for { $f->is_ready };
   $f->get;

   pass( 'Logged in after 230' );
}

# Legacy callback
{
   my $loggedin = 0;

   $ftp->login(
      user => "testuser",
      pass => "secret",
      on_login => sub { $loggedin++ },
      on_error => sub { die "Test failed early - $!" },
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "USER testuser$CRLF", 'USER command' );

   $S2->syswrite( "331 Password Required$CRLF" );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $S2 => $server_stream;

   is( $server_stream, "PASS secret$CRLF", 'PASS command' );

   $S2->syswrite( "230 Logged In$CRLF" );

   wait_for { $loggedin };

   is( $loggedin, 1, '$loggedin after 230' );
}

done_testing;
