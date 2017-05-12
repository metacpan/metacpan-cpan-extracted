#
# $Id: DescL4.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::DescL4;
use strict;
use warnings;
use Carp;

require Net::Packet::Desc;
our @ISA = qw(Net::Packet::Desc);
__PACKAGE__->cgBuildIndices;

use Net::Packet::Consts qw(:desc :layer);

use Socket;
require Socket6;
require Net::Write::Layer4;

sub new {
   my $self = shift->SUPER::new(
      protocol => NP_DESC_IPPROTO_TCP,
      family   => NP_LAYER_IPv4,
      @_,
   );

   confess("@{[(caller(0))[3]]}: you must pass `target' parameter\n")
      unless $self->target;

   my $families = {
      NP_LAYER_IPv4() => AF_INET(),
      NP_LAYER_IPv6() => AF_INET6(),
   };

   my $nwrite = Net::Write::Layer4->new(
      dst      => $self->target,
      family   => $families->{$self->family},
      protocol => $self->protocol,
   );
   $nwrite->open;
   $self->_io($nwrite);

   $self;
}

#
# Helpers
#

sub _isFamily    { shift->family eq shift          }
sub isFamilyIpv4 { shift->_isFamily(NP_LAYER_IPv4) }
sub isFamilyIpv6 { shift->_isFamily(NP_LAYER_IPv6) }

sub _isProtocol      { shift->protocol eq shift                   }
sub isProtocolTcp    { shift->_isProtocol(NP_DESC_IPPROTO_TCP)    }
sub isProtocolUdp    { shift->_isProtocol(NP_DESC_IPPROTO_UDP)    }
sub isProtocolIcmpv4 { shift->_isProtocol(NP_DESC_IPPROTO_ICMPv4) }

1;

__END__

=head1 NAME

Net::Packet::DescL4 - object for a transport layer (layer 4) descriptor

=head1 SYNOPSIS

   require Net::Packet::DescL4;

   # Get NP_DESC_* constants
   use Net::Packet::Consts qw(:desc :layer);

   # Usually, you use it to send TCP and UDP frames over IPv4
   my $d4 = Net::Packet::DescL4->new(
      target   => '192.168.0.1',
      protocol => NP_DESC_IPPROTO_TCP,
      family   => NP_LAYER_IPv4,
   );

   $d4->send($rawStringToNetwork);

=head1 DESCRIPTION

See also B<Net::Packet::Desc> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<target>

IPv4 address of the target host. You must set it to be able to send frames.

=item B<protocol>

Transport protocol to use, see NP_DESC_IPPROTO_* constants in B<Net::Packet::Desc>. You must set it to be able to send frames.

=item B<family>

The family address of B<target> attribute. It is either B<NP_LAYER_IPv4> or B<NP_LAYER_IPv6>.

=back

=head1 METHODS

=over 4

=item B<new>

Create the object, using default B<$Env> object values for B<dev>, B<ip>, B<ip6> and B<mac> (see B<Net::Packet::Env>). When the object is created, the B<$Env> global object has its B<desc> attributes set to it. You can avoid this behaviour
by setting B<noDescAutoSet> in B<$Env> object (see B<Net::Packet::Env>).

Default values for attributes:

dev:      $Env->dev

ip:       $Env->ip

ip6:      $Env->ip6

mac:      $Env->mac

protocol: NP_DESC_IPPROTO_TCP

family:   NP_LAYER_IPv4

=item B<isFamilyIpv4>

=item B<isFamilyIpv6>

=item B<isFamilyIp> - either one of two previous

Helper method to know about the layer 3 type.

=item B<isProtocolTcp>

=item B<isProtocolUdp>

=item B<isProtocolIcmpv4>

Returns if the protocol attribute is of specified type.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
