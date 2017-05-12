#
# $Id: Desc.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::Desc;
use strict;
use warnings;

require Exporter;
require Class::Gomor::Array;
our @ISA = qw(Exporter Class::Gomor::Array);

use Net::Packet::Env qw($Env);
use Net::Packet::Consts qw(:desc);

our @AS = qw(
   dev
   ip
   ip6
   mac
   gatewayIp
   gatewayMac
   target
   targetMac
   protocol
   family
   _io
   _sockaddr
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      dev => $Env->dev,
      ip  => $Env->ip,
      ip6 => $Env->ip6,
      mac => $Env->mac,
      gatewayIp => $Env->gatewayIp,
      @_,
   );

   $self->cgDebugPrint(1, "dev: [@{[$self->dev]}]\n".
                          "ip:  [@{[$self->ip]}]\n".
                          "mac: [@{[$self->mac]}]");
   $self->cgDebugPrint(1, "ip6: [@{[$self->ip6]}]")
      if $self->ip6;
   $self->cgDebugPrint(1, "gatewayIp:  [@{[$self->gatewayIp]}]")
      if $self->gatewayIp;

   $Env->desc($self) unless $Env->noDescAutoSet;

   $self;
}

sub send   { shift->_io->send(shift()) }
sub close  { shift->_io->close         }

#
# Helpers
#

sub _isDesc  { ref(shift) =~ /@{[shift()]}/ }
sub isDescL2 { shift->_isDesc(NP_DESC_L2)   }
sub isDescL3 { shift->_isDesc(NP_DESC_L3)   }
sub isDescL4 { shift->_isDesc(NP_DESC_L4)   }

1;

__END__

=head1 NAME

Net::Packet::Desc - base class for all desc modules

=head1 DESCRIPTION

This is the base class for B<Net::Packet::DescL2>, B<Net::Packet::DescL3> and B<Net::Packet::DescL4> modules.

It just provides those layers with inheritable attributes and methods.

A descriptor is required when you want to send frames over network.

=head1 ATTRIBUTES

=over 4

=item B<dev>

Network device to use to send frames. Default to use B<dev> set in default B<$Env> object.

=item B<ip>

Same as above for IP. This is the source IP address to use.

=item B<ip6>

Same as above for IPv6. This is the source IPv6 address to use.

=item B<mac>

Same as above for MAC. This is the source MAC address to use.

=item B<gatewayIp>

Same as above, for gateway IP address.

=item B<gatewayMac>

Same as above, for gateway MAC address. It is not automatically set here. It is automatically set only under Windows, when using a B<Net::Packet::DescL3> object.

=item B<target>

Used to create a B<Net::Packet::DescL3> and B<Net::Packet::DescL4>. At these layers, one MUST specifiy the target IP address to tell kernel where to send frames.

=item B<targetMac>

Used to automatically build layer 2 when using a B<Net::Packet::DescL3> object under Windows.

=item B<protocol>

This is the transport protocol to use (TCP, UDP, ...). Used in B<Net::Packet::DescL4> objects. Default to TCP.

=item B<family>

Same as abose, to tell which network protocol to use (IPv4, IPv6).

=back

=head1 METHODS

=over 4

=item B<send> (scalar)

Send the raw data passed as a parameter.

=item B<close>

Close the descriptor.

=item B<isDescL2>

=item B<isDescL3>

=item B<isDescL4>

Returns true if Desc is of specified type, false otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:desc);

=over 4

=item B<NP_DESC_IPPROTO_IP>

=item B<NP_DESC_IPPROTO_IPv6>

=item B<NP_DESC_IPPROTO_RAW>

=item B<NP_DESC_IPPROTO_TCP>

=item B<NP_DESC_IPPROTO_UDP>

=item B<NP_DESC_IPPROTO_ICMPv4>

=item B<NP_DESC_IP_HDRINCL>

=item B<NP_DESC_L2>

=item B<NP_DESC_L3>

=item B<NP_DESC_L4>

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
