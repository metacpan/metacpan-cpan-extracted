#!/usr/bin/perl -w

use strict;

use Test::More tests => 23;

BEGIN { 
   $Socket::GetAddrInfo::NO_CORE = 1;
   $Socket::GetAddrInfo::NO_XS = 1;
}
use Socket::GetAddrInfo qw(
   getaddrinfo getnameinfo 
   AI_NUMERICHOST
   NI_NUMERICHOST NI_NUMERICSERV
);

use Socket qw(
   AF_INET SOCK_STREAM IPPROTO_TCP
   pack_sockaddr_in unpack_sockaddr_in inet_aton
);

# Test::More's printing in is() isn't very helpful for addresses.
# Also, since pack_sockaddr_in() doesn't set sin_len on those systems that
# use it (i.e. BSD4.4-derived), we have to be a bit more clever
sub is_sinaddr
{
   my ( $got, $expect_port, $expect_addr, $message ) = @_;

   my ( $port, $sinaddr ) = eval { unpack_sockaddr_in( $got ) };

   if( !defined $port ) {
      diag( "unpack_sockaddr_in failed - $@" );
      fail( $message );
      return;
   }

   if( defined $expect_port && $port != $expect_port ) {
      diag( "Expected port $expect_port, got $port" );
      fail( $message );
      return;
   }

   if( $sinaddr ne $expect_addr ) {
      diag( sprintf 'Expected sinaddr %v02x, got %v02x', $expect_addr, $sinaddr );
      fail( $message );
      return;
   }

   pass( $message );
}

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

my ( $err, @res );

# Some OSes require a socktype hint when given raw numeric service names
( $err, @res ) = getaddrinfo( "127.0.0.1", "80", { socktype => SOCK_STREAM } );
is_err( $err, 0,  '$err == 0 for host=127.0.0.1/service=80/socktype=STREAM' );
is( "$err", "", '$err eq "" for host=127.0.0.1/service=80/socktype=STREAM' );
is( scalar @res, 1,
   '@res has 1 result' );

is( $res[0]->{family}, AF_INET,
   '$res[0] family is AF_INET' );
is( $res[0]->{socktype}, SOCK_STREAM,
   '$res[0] socktype is SOCK_STREAM' );
ok( $res[0]->{protocol} == 0 || $res[0]->{protocol} == IPPROTO_TCP,
   '$res[0] protocol is 0 or IPPROTO_TCP' );
is_sinaddr( $res[0]->{addr}, 80, inet_aton( "127.0.0.1" ),
   '$res[0] addr is {"127.0.0.1", 0}' );

( $err, @res ) = getaddrinfo( "", "80", { family => AF_INET, socktype => SOCK_STREAM } );
is_err( $err, 0,  '$err == 0 for service=80/family=AF_INET/socktype=STREAM' );
is( scalar @res, 1, '@res has 1 result' );

is( $res[0]->{family}, AF_INET,
   '$res[0] family is AF_INET' );
is( $res[0]->{socktype}, SOCK_STREAM,
   '$res[0] socktype is SOCK_STREAM' );
ok( $res[0]->{protocol} == 0 || $res[0]->{protocol} == IPPROTO_TCP,
   '$res[0] protocol is 0 or IPPROTO_TCP' );

( $err, @res ) = getaddrinfo( undef, "80", { family => AF_INET, socktype => SOCK_STREAM } );
is_err( $err, 0,  '$err == 0 for service=80/family=AF_INET/socktype=STREAM' );

my ( $host, $service );

( $err, $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICHOST|NI_NUMERICSERV );
is_err( $err, 0,  '$err == 0 for {family=AF_INET,port=80,sinaddr=127.0.0.1}/NI_NUMERICHOST|NI_NUMERICSERV' );
is( "$err", "", '$err eq "" for {family=AF_INET,port=80,sinaddr=127.0.0.1}/NI_NUMERICHOST|NI_NUMERICSERV' );

is( $host, "127.0.0.1", '$host is 127.0.0.1 for NH/NS' );
is( $service, "80", '$service is 80 for NH/NS' );

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
