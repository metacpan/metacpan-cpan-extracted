#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2011 -- leonerd@leonerd.org.uk

package Socket::GetAddrInfo::Emul;

use strict;
use warnings;

our $VERSION = '0.22';

# Load the actual code into Socket::GetAddrInfo
package # hide from indexer
  Socket::GetAddrInfo;

use Carp;

use Socket;
use Scalar::Util qw( dualvar );

our @EXPORT_OK;

=head1 NAME

C<Socket::GetAddrInfo::Emul> - Pure Perl emulation of C<getaddrinfo> and
C<getnameinfo> using IPv4-only legacy resolvers

=head1 DESCRIPTION

C<Socket::GetAddrInfo> attempts to provide the C<getaddrinfo> and
C<getnameinfo> functions by some XS code that calls the real functions in
F<libc>. If for some reason this cannot be done; either there is no C
compiler, or F<libc> does not provide these functions, then they will be
emulated using the legacy resolvers C<gethostbyname>, etc... These emulations
are not a complete replacement of the real functions, because they only
support IPv4 (the C<AF_INET> socket family). In this case, the following
restrictions will apply.

=cut

# These numbers borrowed from GNU libc's implementation, but since
# they're only used by our emulation, it doesn't matter if the real
# platform's values differ
BEGIN {
   my %constants = (
       AI_PASSIVE     => 1,
       AI_CANONNAME   => 2,
       AI_NUMERICHOST => 4,
       AI_V4MAPPED    => 8,
       AI_ALL         => 16,
       AI_ADDRCONFIG  => 32,
       # RFC 2553 doesn't define this but Linux does - lets be nice and
       # provide it since we can
       AI_NUMERICSERV => 1024,

       EAI_BADFLAGS   => -1,
       EAI_NONAME     => -2,
       EAI_NODATA     => -5,
       EAI_FAMILY     => -6,
       EAI_SERVICE    => -8,

       NI_NUMERICHOST => 1,
       NI_NUMERICSERV => 2,
       NI_NOFQDN      => 4,
       NI_NAMEREQD    => 8,
       NI_DGRAM       => 16,

       # These are not gni() constants; they're extensions for the perl API /*
       NIx_NOHOST     => 1,
       NIx_NOSERV     => 2,

       # Constants we don't support. Export them, but croak if anyone tries to
       # use them
       AI_IDN                      => 64,
       AI_CANONIDN                 => 128,
       AI_IDN_ALLOW_UNASSIGNED     => 256,
       AI_IDN_USE_STD3_ASCII_RULES => 512,
       NI_IDN                      => 32,
       NI_IDN_ALLOW_UNASSIGNED     => 64,
       NI_IDN_USE_STD3_ASCII_RULES => 128,

       # Error constants we'll never return, so it doesn't matter what value
       # these have, nor that we don't provide strings for them
       EAI_SYSTEM   => -11,
       EAI_BADHINTS => -1000,
       EAI_PROTOCOL => -1001
   );

   require constant;
   constant->import( $_ => $constants{$_} ) for keys %constants;
   push @EXPORT_OK, $_ for keys %constants;
}

push @EXPORT_OK, qw(
   getaddrinfo
   getnameinfo
);

my %errstr = (
   # These strings from RFC 2553
   EAI_BADFLAGS()   => "invalid value for ai_flags",
   EAI_NONAME()     => "nodename nor servname provided, or not known",
   EAI_NODATA()     => "no address associated with nodename",
   EAI_FAMILY()     => "ai_family not supported",
   EAI_SERVICE()    => "servname not supported for ai_socktype",
);

# Borrowed from Regexp::Common::net
my $REGEXP_IPv4_DECIMAL = qr/25[0-5]|2[0-4][0-9]|1?[0-9][0-9]{1,2}/;
my $REGEXP_IPv4_DOTTEDQUAD = qr/$REGEXP_IPv4_DECIMAL\.$REGEXP_IPv4_DECIMAL\.$REGEXP_IPv4_DECIMAL\.$REGEXP_IPv4_DECIMAL/;

sub _makeerr
{
   my ( $errno ) = @_;
   my $errstr = $errno == 0 ? "" : ( $errstr{$errno} || $errno );
   return dualvar( $errno, $errstr );
}

=head2 getaddrinfo

=over 4

=item *

If the C<family> hint is supplied, it must be C<AF_INET>. Any other value will
result in an error thrown by C<croak>.

=item *

The only supported C<flags> hint values are C<AI_PASSIVE>, C<AI_CANONNAME>,
C<AI_NUMERICSERV> and C<AI_NUMERICHOST>.

The flags C<AI_V4MAPPED> and C<AI_ALL> are recognised but ignored, as they do
not apply to C<AF_INET> lookups.  Since this function only returns C<AF_INET>
addresses, it does not need to probe the system for configured addresses in
other families, so the C<AI_ADDRCONFIG> flag is also ignored.

Note that C<AI_NUMERICSERV> is an extension not defined by RFC 2553, but is
provided by most OSes. It is possible (though unlikely) that even the native
XS implementation does not recognise this constant.

=back

=cut

sub getaddrinfo
{
   my ( $node, $service, $hints ) = @_;
   
   $node = "" unless defined $node;

   $service = "" unless defined $service;

   my ( $family, $socktype, $protocol, $flags ) = @$hints{qw( family socktype protocol flags )};

   $family ||= AF_INET; # 0 == AF_UNSPEC, which we want too
   $family == AF_INET or return _makeerr( EAI_FAMILY );

   $socktype ||= 0;

   $protocol ||= 0;

   $flags ||= 0;

   my $flag_passive     = $flags & AI_PASSIVE;     $flags &= ~AI_PASSIVE;
   my $flag_canonname   = $flags & AI_CANONNAME;   $flags &= ~AI_CANONNAME;
   my $flag_numerichost = $flags & AI_NUMERICHOST; $flags &= ~AI_NUMERICHOST;
   my $flag_numericserv = $flags & AI_NUMERICSERV; $flags &= ~AI_NUMERICSERV;

   # These constants don't apply to AF_INET-only lookups, so we might as well
   # just ignore them. For AI_ADDRCONFIG we just presume the host has ability
   # to talk AF_INET. If not we'd have to return no addresses at all. :)
   $flags &= ~(AI_V4MAPPED|AI_ALL|AI_ADDRCONFIG);

   $flags & (AI_IDN|AI_CANONIDN|AI_IDN_ALLOW_UNASSIGNED|AI_IDN_USE_STD3_ASCII_RULES) and
      croak "Socket::GetAddrInfo::Emul::getaddrinfo does not support IDN";

   $flags == 0 or return _makeerr( EAI_BADFLAGS );

   $node eq "" and $service eq "" and return _makeerr( EAI_NONAME );

   my $canonname;
   my @addrs;
   if( $node ne "" ) {
      return _makeerr( EAI_NONAME ) if( $flag_numerichost and $node !~ m/^$REGEXP_IPv4_DOTTEDQUAD$/ );
      ( $canonname, undef, undef, undef, @addrs ) = gethostbyname( $node );
      defined $canonname or return _makeerr( EAI_NONAME );

      undef $canonname unless $flag_canonname;
   }
   else {
      $addrs[0] = $flag_passive ? inet_aton( "0.0.0.0" )
                                : inet_aton( "127.0.0.1" );
   }

   my @ports; # Actually ARRAYrefs of [ socktype, protocol, port ]
   my $protname = "";
   if( $protocol ) {
      $protname = getprotobynumber( $protocol );
   }

   if( $service ne "" and $service !~ m/^\d+$/ ) {
      return _makeerr( EAI_NONAME ) if( $flag_numericserv );
      getservbyname( $service, $protname ) or return _makeerr( EAI_SERVICE );
   }

   foreach my $this_socktype ( SOCK_STREAM, SOCK_DGRAM, SOCK_RAW ) {
      next if $socktype and $this_socktype != $socktype;

      my $this_protname = "raw";
      $this_socktype == SOCK_STREAM and $this_protname = "tcp";
      $this_socktype == SOCK_DGRAM  and $this_protname = "udp";

      next if $protname and $this_protname ne $protname;

      my $port;
      if( $service ne "" ) {
         if( $service =~ m/^\d+$/ ) {
            $port = "$service";
         }
         else {
            ( undef, undef, $port, $this_protname ) = getservbyname( $service, $this_protname );
            next unless defined $port;
         }
      }
      else {
         $port = 0;
      }

      push @ports, [ $this_socktype, scalar getprotobyname( $this_protname ) || 0, $port ];
   }

   my @ret;
   foreach my $addr ( @addrs ) {
      foreach my $portspec ( @ports ) {
         my ( $socktype, $protocol, $port ) = @$portspec;
         push @ret, { 
            family    => $family,
            socktype  => $socktype,
            protocol  => $protocol,
            addr      => pack_sockaddr_in( $port, $addr ),
            canonname => undef,
         };
      }
   }

   # Only supply canonname for the first result
   if( defined $canonname ) {
      $ret[0]->{canonname} = $canonname;
   }

   return ( _makeerr( 0 ), @ret );
}

=head2 getnameinfo

=over 4

=item *

If the sockaddr family of C<$addr> is anything other than C<AF_INET>, an error
will be thrown with C<croak>.

=item *

The only supported C<$flags> values are C<NI_NUMERICHOST>, C<NI_NUMERICSERV>,
C<NI_NOFQDN>, C<NI_NAMEREQD> and C<NI_DGRAM>.

=back

=cut

sub getnameinfo
{
   my ( $addr, $flags, $xflags ) = @_;

   my ( $port, $inetaddr );
   eval { ( $port, $inetaddr ) = unpack_sockaddr_in( $addr ) }
      or return _makeerr( EAI_FAMILY );

   my $family = AF_INET;

   $flags ||= 0;

   my $flag_numerichost = $flags & NI_NUMERICHOST; $flags &= ~NI_NUMERICHOST;
   my $flag_numericserv = $flags & NI_NUMERICSERV; $flags &= ~NI_NUMERICSERV;
   my $flag_nofqdn      = $flags & NI_NOFQDN;      $flags &= ~NI_NOFQDN;
   my $flag_namereqd    = $flags & NI_NAMEREQD;    $flags &= ~NI_NAMEREQD;
   my $flag_dgram       = $flags & NI_DGRAM;       $flags &= ~NI_DGRAM;

   $flags & (NI_IDN|NI_IDN_ALLOW_UNASSIGNED|NI_IDN_USE_STD3_ASCII_RULES) and
      croak "Socket::GetAddrInfo::Emul::getnameinfo does not support IDN";

   $flags == 0 or return _makeerr( EAI_BADFLAGS );

   $xflags ||= 0;

   my $node;
   if( $xflags & NIx_NOHOST ) {
      $node = undef;
   }
   elsif( $flag_numerichost ) {
      $node = inet_ntoa( $inetaddr );
   }
   else {
      $node = gethostbyaddr( $inetaddr, $family );
      if( !defined $node ) {
         return _makeerr( EAI_NONAME ) if $flag_namereqd;
         $node = inet_ntoa( $inetaddr );
      }
      elsif( $flag_nofqdn ) {
         my ( $shortname ) = split m/\./, $node;
         my ( $fqdn ) = gethostbyname $shortname;
         $node = $shortname if defined $fqdn and $fqdn eq $node;
      }
   }

   my $service;
   if( $xflags & NIx_NOSERV ) {
      $service = undef;
   }
   elsif( $flag_numericserv ) {
      $service = "$port";
   }
   else {
      my $protname = $flag_dgram ? "udp" : "tcp";
      $service = getservbyport( $port, $protname );
      if( !defined $service ) {
         $service = "$port";
      }
   }

   return ( _makeerr( 0 ), $node, $service );
}

=head1 IDN SUPPORT

This pure-perl emulation provides the IDN constants such as C<AI_IDN> and
C<NI_IDN>, but the C<getaddrinfo> and C<getnameinfo> functions will croak if
passed these flags. This should allow a program to probe for their support,
and fall back to some other behaviour instead.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
