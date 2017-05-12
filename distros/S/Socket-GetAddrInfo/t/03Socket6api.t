#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;

use Socket::GetAddrInfo::Socket6api qw( getaddrinfo getnameinfo NI_NUMERICHOST NI_NUMERICSERV );
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

my @res;

@res = getaddrinfo( "127.0.0.1", "80", 0, SOCK_STREAM, 0, 0 );
is( scalar @res, 5, '@res has 1 result' );

is( $res[0], AF_INET,
   '$res[0] is AF_INET' );
is( $res[1], SOCK_STREAM,
   '$res[1] is SOCK_STREAM' );
ok( $res[2] == 0 || $res[2] == IPPROTO_TCP,
   '$res[2] is 0 or IPPROTO_TCP' );
is_sinaddr( $res[3], 80, inet_aton( "127.0.0.1" ),
   '$res[3] is { "127.0.0.1", 80 }' );

# Now something I hope doesn't exist - we put it in a known-missing TLD
my $missinghost = "TbK4jM2M0OS.lm57DWIyu4i";

# Some CPAN testing machines seem to have wildcard DNS servers that reply to
# any request. We'd better check for them

SKIP: {
   skip "Resolver has an answer for $missinghost", 1 if gethostbyname( $missinghost );

   @res = getaddrinfo( $missinghost, 80, 0, SOCK_STREAM, 0, 0 );
   is( scalar @res, 1, '@res contains an error' );
}

my ( $host, $service ) = getnameinfo( pack_sockaddr_in( 80, inet_aton( "127.0.0.1" ) ), NI_NUMERICHOST|NI_NUMERICSERV );
is( $host, "127.0.0.1", '$host is 127.0.0.1' );
is( $service, "80", '$service is 80' );
