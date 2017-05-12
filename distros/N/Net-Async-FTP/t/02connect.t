#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::Stream;
use IO::Socket::INET;

use Net::Async::FTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

# Can't use name "localhost" in case it resolves

my $serversock = IO::Socket::INET->new( 
   Type      => SOCK_STREAM,
   LocalHost => "localhost",
   Listen    => 1
) or die "Cannot create server socket - $!";

$serversock->blocking(0);

# ->connect future
{
   my $ftp = Net::Async::FTP->new();
   $loop->add( $ftp );

   my $connect_f = $ftp->connect(
      host    => "localhost",
      service => $serversock->sockport,
      family  => AF_INET,

      user => "testuser",
      pass => "secret",
   );

   my $newclient;
   wait_for { $newclient = $serversock->accept };

   $newclient->syswrite( "220 Welcome to FTP$CRLF" );

   wait_for { $connect_f->is_ready };
   $connect_f->get;

   my $login_f = $ftp->login(
      user => "testuser",
      pass => "secret",
   );

   my $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $newclient => $server_stream;

   is( $server_stream, "USER testuser$CRLF", 'USER command' );

   $newclient->syswrite( "331 Password Required$CRLF" );

   $server_stream = "";
   wait_for_stream { $server_stream =~ m/$CRLF/ } $newclient => $server_stream;

   is( $server_stream, "PASS secret$CRLF", 'PASS command' );

   $newclient->syswrite( "230 Logged In$CRLF" );

   wait_for { $login_f->is_ready };
   $login_f->get;

   pass( 'Logged in after 230' );

   $loop->remove( $ftp );
}

# Legacy callback
{
   my $ftp = Net::Async::FTP->new();
   $loop->add( $ftp );

   my $connected = 0;

   $ftp->connect(
      host    => "localhost",
      service => $serversock->sockport,
      family  => AF_INET,

      user => "testuser",
      pass => "secret",

      on_connected => sub { $connected++ },
      on_error     => sub { die "Test failed early - $_[0]" },
   );

   my $newclient;
   wait_for { $newclient = $serversock->accept };

   $newclient->syswrite( "220 Welcome to FTP$CRLF" );

   wait_for { $connected };

   is( $connected, 1, '$connected after 220' );
}

done_testing;
