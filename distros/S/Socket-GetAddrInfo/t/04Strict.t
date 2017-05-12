#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

use Socket::GetAddrInfo::Strict qw( getaddrinfo getnameinfo NI_NUMERICHOST NI_NUMERICSERV );
use Socket qw( AF_INET SOCK_STREAM IPPROTO_TCP pack_sockaddr_in unpack_sockaddr_in inet_aton );

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

   if( $port != $expect_port ) {
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

my @res = getaddrinfo( "127.0.0.1", "80", { socktype => SOCK_STREAM } );

is( $res[0]->{family}, AF_INET,
   '$res[0] family is AF_INET' );
is( $res[0]->{socktype}, SOCK_STREAM,
   '$res[0] socktype is SOCK_STREAM' );
ok( $res[0]->{protocol} == 0 || $res[0]->{protocol} == IPPROTO_TCP,
   '$res[0] protocol is 0 or IPPROTO_TCP' );
is_sinaddr( $res[0]->{addr}, 80, inet_aton( "127.0.0.1" ),
   '$res[0] addr is {"127.0.0.1", 0}' );

# Now something I hope doesn't exist - we put it in a known-missing TLD
my $missinghost = "TbK4jM2M0OS.lm57DWIyu4i";

# Some CPAN testing machines seem to have wildcard DNS servers that reply to
# any request. We'd better check for them

SKIP: {
   skip "Resolver has an answer for $missinghost", 1 if gethostbyname( $missinghost );

   ok( !eval { getaddrinfo( $missinghost, 80, { socktype => SOCK_STREAM } ); 1 }, 'getaddrinfo missing host dies' );
}

my ( $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICHOST|NI_NUMERICSERV );
is( $host, "127.0.0.1", '$host is 127.0.0.1' );
is( $service, "80", '$service is 80' );
