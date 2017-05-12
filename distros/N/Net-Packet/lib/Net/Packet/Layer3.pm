#
# $Id: Layer3.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::Layer3;
use strict;
use warnings;

require Net::Packet::Layer;
our @ISA = qw(Net::Packet::Layer);
__PACKAGE__->cgBuildIndices;

use Net::Packet::Consts qw(:layer);

sub layer { NP_LAYER_N_3 }

sub _is    { (shift->is eq shift()) ? 1 : 0                   }
sub isIp   { my $self = shift; $self->isIpv4 || $self->isIpv6 }
sub isIpv4 { shift->_is(NP_LAYER_IPv4)                        }
sub isIpv6 { shift->_is(NP_LAYER_IPv6)                        }
sub isArp  { shift->_is(NP_LAYER_ARP)                         }
sub isVlan { shift->_is(NP_LAYER_VLAN)                        }

1;

__END__

=head1 NAME

Net::Packet::Layer3 - base class for all layer 3 modules

=head1 DESCRIPTION

This is the base class for B<Net::Packet::Layer3> subclasses.

It just provides those layers with inheritable attributes and methods.

=head1 METHODS

=over 4

=item B<isIpv4>

=item B<isIpv6>

=item B<isIp> - is IPv4 or IPv6

=item B<isArp>

=item B<isVlan>

Returns true if Layer3 is of specified type, false otherwise.

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
