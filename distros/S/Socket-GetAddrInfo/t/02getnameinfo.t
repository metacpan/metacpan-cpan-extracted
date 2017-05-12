#!/usr/bin/perl -w

use strict;

use Test::More tests => 18;

use Socket::GetAddrInfo qw( getnameinfo NI_NUMERICHOST NI_NUMERICSERV NI_NAMEREQD NIx_NOHOST NIx_NOSERV );

use Socket qw( AF_INET pack_sockaddr_in inet_aton );

sub err_to_const
{
   my ( $err ) = @_;

   return "EAI_NOERROR" if $err == 0;

   no strict 'refs';

   foreach my $const ( keys %{"Socket::GetAddrInfo::"} ) {
      next unless $const =~ m/^EAI_/;

      my $sub = "Socket::GetAddrInfo::$const";
      return $const if $sub->() == $err;
   }

   return undef;
}

sub is_err
{
   my ( $got, $expect, $message ) = @_;

   if( $got == $expect ) {
      pass( $message );
      return;
   }

   my $got_const    = err_to_const( $got );
   my $expect_const = err_to_const( $expect );

   if( defined $got_const ) {
      diag( "Expected err == $expect_const, got err == $got_const" );
      fail( $message );
   }
   else {
      diag( "Expected err == $expect_const, got err == unknown ('$got')" );
      fail( $message );
   }
}

my ( $err, $host, $service );

( $err, $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICHOST|NI_NUMERICSERV );
is_err( $err, 0,  '$err == 0 for {family=AF_INET,port=80,sinaddr=127.0.0.1}/NI_NUMERICHOST|NI_NUMERICSERV' );
is( "$err", "", '$err eq "" for {family=AF_INET,port=80,sinaddr=127.0.0.1}/NI_NUMERICHOST|NI_NUMERICSERV' );

is( $host, "127.0.0.1", '$host is 127.0.0.1 for NH/NS' );
is( $service, "80", '$service is 80 for NH/NS' );

( $err, $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICHOST|NI_NUMERICSERV, NIx_NOHOST );
is( $host, undef, '$host is undef for NIx_NOHOST' );
is( $service, "80", '$service is 80 for NS, NIx_NOHOST' );

( $err, $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICHOST|NI_NUMERICSERV, NIx_NOSERV );
is( $host, "127.0.0.1", '$host is undef for NIx_NOSERV' );
is( $service, undef, '$service is 80 for NS, NIx_NOSERV' );

# Probably "localhost" but we'd better ask the system to be sure
my $expect_host = gethostbyaddr( inet_aton( "127.0.0.1" ), AF_INET );
defined $expect_host or $expect_host = "127.0.0.1";

( $err, $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICSERV );
is_err( $err, 0,  '$err == 0 for {family=AF_INET,port=80,sinaddr=127.0.0.1}/NI_NUMERICSERV' );

is( $host, $expect_host, "\$host is $expect_host for NS" );
is( $service, "80", '$service is 80 for NS' );

# Probably "www" but we'd better ask the system to be sure
my $expect_service = getservbyport( 80, "tcp" );
defined $expect_service or $expect_service = "80";

( $err, $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICHOST );
is_err( $err, 0,  '$err == 0 for {family=AF_INET,port=80,sinaddr=127.0.0.1}/NI_NUMERICHOST' );

is( $host, "127.0.0.1", '$host is 127.0.0.1 for NH' );
is( $service, $expect_service, "\$service is $expect_service for NH" );

# This is hard. We need to find an IP address we can guarantee will not have
# a name. Simple solution is to find one.

my $addr;
my $num;

foreach ( 1 .. 254 ) {
   my $candidate_addr = pack_sockaddr_in( 80, inet_aton( "192.168.$_.$_" ) );

   my ( $err ) = getnameinfo( $candidate_addr, NI_NAMEREQD );
   if( !$err ) {
      next;
   }
   else {
      $addr = $candidate_addr;
      $num = $_;
      last;
   }
}

SKIP: {
   skip "Cannot find an IP address without a name in 192.168/24", 4 unless defined $addr;

   ( $err, $host, $service ) = getnameinfo( $addr, NI_NUMERICHOST );
   is_err( $err, 0, "\$err == 0 for {family=AF_INET,port=80,sinaddr=192.168.$num.$num}" );

   is( $host, "192.168.$num.$num", "\$host is 192.168.$num.$num" );
   is( $service, $expect_service, "\$service is $expect_service" );

   ( $err, $host, $service ) = getnameinfo( $addr, NI_NAMEREQD );
   ok( $err != 0, "\$err != 0 for {family=AF_INET,port=80,sinaddr=192.168.$num.$num}/NI_NAMEREQD" );
}
