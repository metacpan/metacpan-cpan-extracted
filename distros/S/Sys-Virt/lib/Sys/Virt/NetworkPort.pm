# -*- perl -*-
#
# Copyright (C) 2019 Red Hat
#
# This program is free software; You can redistribute it and/or modify
# it under either:
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any
#   later version,
#
# or
#
# b) the "Artistic License"
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions of the two licenses.

=pod

=head1 NAME

Sys::Virt::NetworkPort - Represent & manage a libvirt virtual network port

=head1 DESCRIPTION

The C<Sys::Virt::NetworkPort> module represents a port in a virtual network.

=head1 METHODS

=over 4

=cut

package Sys::Virt::NetworkPort;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $net = exists $params{network} ? $params{network} : die "network parameter is required";
    my $self;
    if (exists $params{uuid}) {
	if (length($params{uuid}) == 16) {
	    $self = Sys::Virt::NetworkPort::_lookup_by_uuid($net,  $params{uuid});
	} elsif (length($params{uuid}) == 32 ||
		 length($params{uuid}) == 36) {
	    $self = Sys::Virt::NetworkPort::_lookup_by_uuid_string($net,  $params{uuid});
	} else {
	    die "UUID must be either 16 unsigned bytes, or 32/36 hex characters long";
	}
    } elsif (exists $params{xml}) {
	my $flags = $params{flags} || 0;
	$self = Sys::Virt::NetworkPort::_create_xml($net,  $params{xml}, $flags);
    } else {
	die "uuid or xml parameters are required";
    }

    bless $self, $class;

    return $self;
}


=item my $uuid = $net->get_uuid()

Returns a 16 byte long string containing the raw globally unique identifier
(UUID) for the network port.

=item my $uuid = $net->get_uuid_string()

Returns a printable string representation of the raw UUID, in the format
'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'.

=item my $xml = $net->get_xml_description()

Returns an XML document containing a complete description of
the network port's configuration

=item $net->delete()

Delete the network port from the managed network.

=item my $params = $net->get_parameters($flags=0);

Get tunable parameters associated with the network port. The C<$flags>
parameter is currently unused and defaults to zero. The returned
C<$params> is a hash reference whose keys are one or more of the
following constants:

=over 4

=item Sys::Virt::NetworkPort::BANDWIDTH_IN_AVERAGE

The average inbound bandwidth

=item Sys::Virt::NetworkPort::BANDWIDTH_IN_BURST

The burstable inbound bandwidth

=item Sys::Virt::NetworkPort::BANDWIDTH_IN_FLOOR

The minimum inbound bandwidth

=item Sys::Virt::NetworkPort::BANDWIDTH_IN_PEAK

The peak inbound bandwidth

=item Sys::Virt::NetworkPort::BANDWIDTH_OUT_AVERAGE

The average outbound bandwidth

=item Sys::Virt::NetworkPort::BANDWIDTH_OUT_BURST

The burstable outbound bandwidth

=item Sys::Virt::NetworkPort::BANDWIDTH_OUT_PEAK

The peak outbound bandwidth

=back

=item $net->set_parameters($params, $flags=0);

Set tunable parameters associated with the network port. The C<$flags>
parameter is currently unused and defaults to zero. The C<$params>
parameter is a hash reference whose keys are one or more of the
constants listed for C<get_parameters>.

=back

=head2 NETWORK PORT CREATION CONSTANTS

When creating network ports zero or more of the following
constants may be used

=over 4

=item Sys::Virt::NetworkPort::CREATE_RECLAIM

Providing configuration reclaiming a pre-existing network port.

=back


=cut


1;


=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2019 Red Hat

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt>, L<Sys::Virt::Network>, L<Sys::Virt::Error>, C<http://libvirt.org>

=cut
