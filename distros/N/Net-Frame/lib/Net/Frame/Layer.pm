#
# $Id: Layer.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer;
use strict;
use warnings;

require Class::Gomor::Array;
require Exporter;
our @ISA = qw(Class::Gomor::Array Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_LAYER_NONE
      NF_LAYER_UNKNOWN
      NF_LAYER_NOT_AVAILABLE 
   )],
   subs => [qw(
      getHostIpv4Addr
      getHostIpv4Addrs
      getHostIpv6Addr
      inetAton
      inetNtoa
      inet6Aton
      inet6Ntoa
      getRandomHighPort
      getRandom32bitsInt
      getRandom16bitsInt
      convertMac
      inetChecksum
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{subs}},
);

use constant NF_LAYER_NONE          => 0;
use constant NF_LAYER_UNKNOWN       => 1;
use constant NF_LAYER_NOT_AVAILABLE => 2;

our @AS = qw(
   raw
   payload
   nextLayer
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

use Carp;

sub new { shift->SUPER::new(nextLayer => NF_LAYER_NONE, @_) }

sub layer {
   my $layer = ref(shift);
   $layer =~ s/^Net::Frame::Layer:://;
   $layer;
}

# XXX: may use some optimizations
sub pack {
   my $self = shift;
   my ($fmt, @args) = @_;
   my $res;
   eval { $res = CORE::pack($fmt, @args) };
   $@ ? do { carp("@{[ref($self)]}: unable to pack structure\n"); undef }
      : $res;
}

sub unpack {
   my $self = shift;
   my ($fmt, $arg) = @_;
   my @res;
   eval { @res = CORE::unpack($fmt, $arg) };
   $@ ? do { carp("@{[ref($self)]}: unable to unpack structure\n"); () }
      : @res;
}

sub getPayloadLength {
   my $self = shift;
   $self->payload ? length($self->payload) : 0;
}

sub encapsulate      { shift->nextLayer              }
sub computeLengths   { 1                             }
sub computeChecksums { 1                             }
sub print            { $self->layer.': to implement' }
sub getLength        { 0                             }

sub dump { CORE::unpack('H*', shift->raw) }

#
# Useful subroutines
#

# Load AF_INET and default imports from Socket. Safe back to at least 5.8.8.
use Socket qw(:DEFAULT AF_INET);

sub _setInet6Sub {
   no strict 'refs';

   my $inetp_found = 0;

   # Check Socket against some IPv6 functions and constants.
   eval {
      require Socket;
      Socket->import(qw(AF_INET6 inet_pton inet_ntop));
   };
   if (! $@) {   # Socket has support for required functions and constants.
      *{__PACKAGE__.'::_inet_pton'} = \&Socket::inet_pton;
      *{__PACKAGE__.'::_inet_ntop'} = \&Socket::inet_ntop;

      $inetp_found = 1;
   }

   # Fallback to Socket6
   if (! $inetp_found) {
      eval {
         require Socket6;
         Socket6->import(qw(AF_INET6 inet_pton inet_ntop));
      };
      if (! $@) {   # Socket6 has support for required functions and constants.
         *{__PACKAGE__.'::_inet_pton'} = \&Socket6::inet_pton;
         *{__PACKAGE__.'::_inet_ntop'} = \&Socket6::inet_ntop;
      }
   }

   # Unfortunately, we have to test if inet_ntop()/inet_pton() works (i.e., are implemented)
   # If no support for inet_ntop/inet_pton, we branch to fake functions.
   if ($inetp_found) {
      eval {
         # inet_pton() may exist, but die with:
         # inet_pton not implemented on this architecture
         _inet_pton(AF_INET6(), "::1");
      };
      if ($@) {
         print "[!] inet_pton support: $@\n";
         *{__PACKAGE__.'::_inet_pton'} = sub { return 0; };
         *{__PACKAGE__.'::_inet_ntop'} = sub { return 0; };
      }
      else {
         return 1;   # OK
      }
   }

   die("[-] Net::Frame: inet_pton/inet_ntop: not supported by Socket nor Socket6: ".
       "try upgrading your Perl version or Socket/Socket6 modules.\n");
}

sub _setGetAddressSub {
   no strict 'refs';

   my $getaddr_found = 0;

   # Check Socket against some IPv6 functions and constants.
   eval {
      require Socket;
      Socket->import(qw(getaddrinfo getnameinfo AF_INET6));
   };
   if (! $@) {   # Socket has support for required functions and constants.
      *{__PACKAGE__.'::_getAddress'} = sub {
         my ($name) = @_;

         #print STDERR "*** Socket supports IPv6 OK\n";

         my %hints = (
            family => Socket::AF_INET6(),
         );
         my ($err, @res) = Socket::getaddrinfo($name, '', \%hints);
         if ($err) {
            carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname: getaddrinfo: $err\n");
            return;
         }
         if (@res > 0) {
            my $h = $res[0];
            my ($err, $ipv6) = Socket::getnameinfo(
               $h->{addr}, Socket::NI_NUMERICHOST() | Socket::NI_NUMERICSERV()
            );
            if ($err) {
               carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname: getnameinfo: $err\n");
               return;
            }

            return $ipv6;
         }
         else {
            carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname: getaddrinfo: $!\n");
            return;
         }
      };

      $getaddr_found = 1;
   }

   # Fallback to Socket6
   if (! $getaddr_found) {
      eval {
         require Socket6;
         Socket6->import(qw(getaddrinfo getnameinfo AF_INET6));
      };
      if (! $@) {   # Socket6 has support for required functions and constants.
         *{__PACKAGE__.'::_getAddress'} = sub {
            my ($name) = @_;

            #print STDERR "*** Fallback to Socket6 support\n";

            my @res = Socket6::getaddrinfo($name, '', Socket6::AF_INET6(), SOCK_STREAM);
            if (@res >= 5) {
               my ($ipv6) = Socket6::getnameinfo(
                  $res[3], Socket6::NI_NUMERICHOST() | Socket6::NI_NUMERICSERV()
               );

               return $ipv6;
            }
         };
      }

      $getaddr_found = 1;
   }

   # Unfortunately, we have to test if INET6 family is supported
   # If no support, we branch to fake functions.
   if ($getaddr_found) {
      eval {
         # getaddrinfo() may exist, but die with:
         # getaddrinfo: ai_family not supported
         _getAddress("::1");
      };
      if ($@) {
         print "[!] getaddrinfo support: $@\n";
         *{__PACKAGE__.'::_getAddress'} = sub { return 0; };
         *{__PACKAGE__.'::_getAddress'} = sub { return 0; };
      }
      else {
         return 1;   # OK
      }
   }

   die("[-] Net::Frame: getaddrinfo/getnameinfo: not supported by Socket nor Socket6: ".
       "try upgrading your Perl version or Socket/Socket6 modules.\n");
}

BEGIN {
   _setInet6Sub();
   _setGetAddressSub();
}

require Net::IPv6Addr;

sub getHostIpv4Addr {
   my ($name) = @_;

   # No address given
   if (! defined($name)) {
      return;
   }

   # Already an IPv4 address
   if ($name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
      return $name;
   }

   my @addrs = (gethostbyname($name))[4];
   @addrs ? return join('.', CORE::unpack('C4', $addrs[0]))
          : carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname\n");

   # Error
   return;
}

sub getHostIpv4Addrs {
   my ($name) = @_;

   # No address given
   if (! defined($name)) {
      return;
   }

   # Already an IPv4 address
   if ($name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
      return $name;
   }

   my @addrs = (gethostbyname($name))[4];
   @addrs ? return @addrs
          : carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname\n");

   # Error
   return ();
}

sub getHostIpv6Addr {
   my ($name) = @_;

   # No address given
   if (! defined($name)) {
      return;
   }

   # Already an IPv6 address
   if (Net::IPv6Addr::is_ipv6($name)) {
      return $name;
   }

   my $ipv6 = _getAddress($name);
   if (! defined($ipv6)) {
      carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname\n");
      return;
   }

   $ipv6 =~ s/%.*$//;

   return $ipv6;
}

sub inetAton  { Socket::inet_aton(shift()) }
sub inetNtoa  { Socket::inet_ntoa(shift()) }
sub inet6Aton { _inet_pton(AF_INET6, shift()) }
sub inet6Ntoa { _inet_ntop(AF_INET6, shift()) }

sub getRandomHighPort {
   my $highPort = int rand 0xffff;
   $highPort += 1024 if $highPort < 1025;
   $highPort;
}

sub getRandom32bitsInt { int rand 0xffffffff }
sub getRandom16bitsInt { int rand 0xffff     }

sub convertMac {
   return lc(join(':', $_[0] =~ /../g));
}

sub inetChecksum {
   my ($phpkt) = @_;

   $phpkt      .= "\x00" if length($phpkt) % 2;
   my $len      = length $phpkt;
   my $nshort   = $len / 2;
   my $checksum = 0;
   $checksum   += $_ for CORE::unpack("S$nshort", $phpkt);
   # XXX: This line never does anything as the lenth was made even above. Currently testing it breaks nothing.
   #$checksum   += CORE::unpack('C', substr($phpkt, $len - 1, 1)) if $len % 2;
   $checksum    = ($checksum >> 16) + ($checksum & 0xffff);

   CORE::unpack('n',
      CORE::pack('S', ~(($checksum >> 16) + $checksum) & 0xffff),
   );
}

1;

__END__

=head1 NAME

Net::Frame::Layer - base class for all layer objects

=head1 DESCRIPTION

This is the base class for all other layer modules. It provides those layers with inheritable attributes, methods, constants and useful subroutines.

=head1 ATTRIBUTES

=over 4

=item B<raw>

Stores the raw layer (as captured from the network, or packed to send to network).

=item B<payload>

Stores what is not part of the layer, that is the encapsulated part to be decoded by upper layers.

=item B<nextLayer>

User definable next layer. It may be used to define custom protocols.

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor.

=item B<layer>

Returns the string describing the layer (example: 'IPv4' for a B<Net::Frame::Layer::IPv4> object).

=item B<computeLengths>

=item B<computeChecksums>

Generally, when a layer is built, some attributes are not yet known until all layers that will be assembled are known. Those methods computes various lengths and checksums attributes found in a specific layer. Return 1 on success, undef otherwise. The usage depends from layer to layer, so see related documentation.

Also note that in most cases, you will need to call B<computeLength> before B<computeChecksums>, because checksums may depend upon lengths.

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns the raw packed string on success, undef otherwise. Result is stored into B<raw> attribute.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns B<$self> on success, undef otherwise.

=item B<encapsulate>

Returns the next layer type (parsed from payload). This is the same string as returned by B<layer> method.

=item B<getLength>

Returns the layer length in bytes.

=item B<getPayloadLength>

Returns the length of layer's payload in bytes.

=item B<print>

Just returns a string in a human readable format describing attributes found in the layer.

=item B<dump>

Just returns a string in hexadecimal format which is how the layer appears on the network.

=back

=head1 USEFUL SUBROUTINES

Load them: use Net::Frame::Layer qw(:subs);

=over 4

=item B<getHostIpv4Addr> (hostname)

Resolves IPv4 address of specified hostname.

=item B<getHostIpv4Addrs> (hostname)

Same as above, but returns an array of IPv4 addresses.

=item B<getHostIpv6Addr> (hostname)

Resolves IPv6 address of specified hostname.

=item B<inet6Aton> (IPv6 address)

Takes IPv6 address and returns the network form.

=item B<inet6Ntoa> (IPv6 network form)

Takes IPv6 address in network format, and returns the IPv6 human form.

=item B<inetAton> (IPv4 address)

=item B<inetNtoa> (IPv4 network form)

Same as for IPv6, but for IPv4 addresses.

=item B<convertMac> (MAC network form)

Takes a MAC address from network form, and returns the human form.

=item B<getRandom16bitsInt>

=item B<getRandom32bitsInt>

Returns respectively a random 16 bits integer, and a random 32 bits integer.

=item B<getRandomHighPort>

Returns a random high port (> 1024).

=item B<inetChecksum> (pseudo header format)

Will take a frame in pseudo header format, and compute the INET checksum.

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer qw(:consts);

=over 4

=item B<NF_LAYER_NONE>

=item B<NF_LAYER_UNKNOWN>

=item B<NF_LAYER_NOT_AVAILABLE>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
