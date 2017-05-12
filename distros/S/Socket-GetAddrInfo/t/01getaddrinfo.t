#!/usr/bin/perl -w

use strict;

use Test::More tests => 39;

use Socket::GetAddrInfo qw( getaddrinfo AI_NUMERICHOST );

use Socket qw( AF_INET SOCK_STREAM IPPROTO_TCP unpack_sockaddr_in inet_aton );

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

# Check actual IV integers work just as well as PV strings
( $err, @res ) = getaddrinfo( "127.0.0.1", 80, { socktype => SOCK_STREAM } );
is_err( $err, 0,  '$err == 0 for host=127.0.0.1/service=80/socktype=STREAM' );
is_sinaddr( $res[0]->{addr}, 80, inet_aton( "127.0.0.1" ),
   '$res[0] addr is {"127.0.0.1", 0}' );

( $err, @res ) = getaddrinfo( "127.0.0.1", "" );
is_err( $err, 0,  '$err == 0 for host=127.0.0.1' );
# Might get more than one; e.g. different socktypes
ok( scalar @res > 0, '@res has results' );

( $err, @res ) = getaddrinfo( "127.0.0.1", undef );
is_err( $err, 0,  '$err == 0 for host=127.0.0.1' );

{
   "127.0.0.1" =~ /(.+)/;
   ( $err, @res ) = getaddrinfo($1, undef);
   is_err( $err, 0,  '$err == 0 for host=$1' );
   ok( scalar @res > 0, '@res has results' );
   is_sinaddr( $res[0]->{addr}, undef, inet_aton( "127.0.0.1" ),
      '$res[0] addr is "127.0.0.1"');
}

{
    package MyString;
    use overload '""' => sub { ${ $_[0] } }, fallback => 1;
    sub new {
       my ($class, $string) = @_;
       return bless \$string, $class;
    }
}

{
   ( $err, @res ) = getaddrinfo(MyString->new("127.0.0.1"), undef);
   is_err( $err, 0,  '$err == 0 for host=MyString->new("127.0.0.1")' );
   ok( scalar @res > 0, '@res has results' );
   is_sinaddr( $res[0]->{addr}, undef, inet_aton( "127.0.0.1" ),
      '$res[0] addr is "127.0.0.1"');
}

{
   ( $err, @res ) = getaddrinfo(substr("127.0.0.1", 0, 9), undef);
   is_err( $err, 0,  '$err == 0 for host=substr("127.0.0.1", 0, 9)' );
   ok( scalar @res > 0, '@res has results' );
   is_sinaddr( $res[0]->{addr}, undef, inet_aton( "127.0.0.1" ),
      '$res[0] addr is "127.0.0.1"');
}

# Just pick the first one
is( $res[0]->{family}, AF_INET,
   '$res[0] family is AF_INET' );
is_sinaddr( $res[0]->{addr}, 0, inet_aton( "127.0.0.1" ),
   '$res[0] addr is {"127.0.0.1", 0}' );

( $err, @res ) = getaddrinfo( "", "80", { family => AF_INET, socktype => SOCK_STREAM } );
is_err( $err, 0,  '$err == 0 for service=80/family=AF_INET/socktype=STREAM' );
is( scalar @res, 1, '@res has 1 result' );

# Just pick the first one
is( $res[0]->{family}, AF_INET,
   '$res[0] family is AF_INET' );
is( $res[0]->{socktype}, SOCK_STREAM,
   '$res[0] socktype is SOCK_STREAM' );
ok( $res[0]->{protocol} == 0 || $res[0]->{protocol} == IPPROTO_TCP,
   '$res[0] protocol is 0 or IPPROTO_TCP' );

( $err, @res ) = getaddrinfo( undef, "80", { family => AF_INET, socktype => SOCK_STREAM } );
is_err( $err, 0,  '$err == 0 for service=80/family=AF_INET/socktype=STREAM' );

# Now some tests of a few well-known internet hosts
my $goodhost = "cpan.perl.org";

SKIP: {
   skip "Resolver has no answer for $goodhost", 2 unless gethostbyname( $goodhost );

   ( $err, @res ) = getaddrinfo( "cpan.perl.org", "ftp", { socktype => SOCK_STREAM } );
   is_err( $err, 0,  '$err == 0 for host=cpan.perl.org/service=ftp/socktype=STREAM' );
   # Might get more than one; e.g. different families
   ok( scalar @res > 0, '@res has results' );
}

# Now something I hope doesn't exist - we put it in a known-missing TLD
my $missinghost = "TbK4jM2M0OS.lm57DWIyu4i";

# Some CPAN testing machines seem to have wildcard DNS servers that reply to
# any request. We'd better check for them

SKIP: {
   skip "Resolver has an answer for $missinghost", 1 if gethostbyname( $missinghost );

   # Some OSes return $err == 0 but no results
   ( $err, @res ) = getaddrinfo( $missinghost, "ftp", { socktype => SOCK_STREAM } );
   ok( $err != 0 || ( $err == 0 && @res == 0 ),
      '$err != 0 or @res == 0 for host=TbK4jM2M0OS.lm57DWIyu4i/service=ftp/socktype=SOCK_STREAM' );
   if( @res ) {
      # Diagnostic that might help
      while( my $r = shift @res ) {
         diag( "family=$r->{family} socktype=$r->{socktype} protocol=$r->{protocol} addr=[" . length( $r->{addr} ) . " bytes]" );
         diag( "  addr=" . join( ", ", map { sprintf '0x%02x', ord $_ } split m//, $r->{addr} ) );
      }
   }
}

# Now something I hope doesn't exist - we put it guess at a named port

( $err, @res ) = getaddrinfo( "127.0.0.1", "ZZgetaddrinfoNameTest", { socktype => SOCK_STREAM } );
ok( $err != 0, '$err != 0 for host=127.0.0.1/service=ZZgetaddrinfoNameTest/socktype=SOCK_STREAM' );

# Now check that names with AI_NUMERICHOST fail

( $err, @res ) = getaddrinfo( "localhost", "ftp", { flags => AI_NUMERICHOST, socktype => SOCK_STREAM } );
ok( $err != 0, '$err != 0 for host=localhost/service=ftp/flags=AI_NUMERICHOST/socktype=SOCK_STREAM' );

# Some sanity checking on the hints hash
ok( defined eval { getaddrinfo( "127.0.0.1", "80", undef ); 1 },
         'getaddrinfo() with undef hints works' );
ok( !defined eval { getaddrinfo( "127.0.0.1", "80", "hints" ); 1 },
         'getaddrinfo() with string hints dies' );
ok( !defined eval { getaddrinfo( "127.0.0.1", "80", [] ); 1 },
         'getaddrinfo() with ARRAY hints dies' );

# Ensure it doesn't segfault if args are missing

( $err, @res ) = getaddrinfo();
ok( defined $err, '$err defined for getaddrinfo()' );

( $err, @res ) = getaddrinfo( "127.0.0.1" );
ok( defined $err, '$err defined for getaddrinfo("127.0.0.1")' );
