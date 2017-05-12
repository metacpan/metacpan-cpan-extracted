# -*- perl -*-
#
# Copyright (C) 2006-2009 Red Hat
# Copyright (C) 2006-2007 Daniel P. Berrange
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

Sys::Virt::Interface - Represent & manage a libvirt host network interface

=head1 DESCRIPTION

The C<Sys::Virt::Interface> module represents a host network interface
allowing configuration of IP addresses, bonding, vlans and bridges.

=head1 METHODS

=over 4

=cut

package Sys::Virt::Interface;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $con = exists $params{connection} ? $params{connection} : die "connection parameter is requried";
    my $self;
    if (exists $params{name}) {
	$self = Sys::Virt::Interface::_lookup_by_name($con,  $params{name});
    } elsif (exists $params{mac}) {
	$self = Sys::Virt::Interface::_lookup_by_mac($con,  $params{mac});
    } elsif (exists $params{xml}) {
	$self = Sys::Virt::Interface::_define_xml($con,  $params{xml});
    } else {
	die "name, mac or xml parameters are required";
    }

    bless $self, $class;

    return $self;
}


=item my $name = $iface->get_name()

Returns a string with a locally unique name of the network

=item $iface->is_active()

Returns a true value if the interface is currently running

=item my $name = $iface->get_mac()

Returns a string with the hardware MAC address of the interface

=item my $xml = $iface->get_xml_description()

Returns an XML document containing a complete description of
the network's configuration

=item $iface->create()

Start a network whose configuration was previously defined using the
C<define_network> method in L<Sys::Virt>.

=item $iface->undefine()

Remove the configuration associated with a network previously defined
with the C<define_network> method in L<Sys::Virt>. If the network is
running, you probably want to use the C<shutdown> or C<destroy>
methods instead.

=item $iface->destroy()

Immediately terminate the machine, and remove it from the virtual
machine monitor. The C<$iface> handle is invalid after this call
completes and should not be used again.

=back

=head1 CONSTANTS

=head1 CONSTANTS

This section documents constants that are used with various
APIs described above

=head2 LIST FILTERING

The following constants are used to filter object lists

=over 4

=item Sys::Virt::Interface::LIST_ACTIVE

Include interfaces that are active

=item Sys::Virt::Interface::LIST_INACTIVE

Include interfaces that are not active

=back

=head2 XML CONSTANTS

The following constants are used when querying XML

=over 4

=item Sys::Virt::Interface::XML_INACTIVE

Request the inactive XML, instead of the current possibly live config.

=back

=cut

1;

=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2006-2009 Red Hat
Copyright (C) 2006-2007 Daniel P. Berrange

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt>, L<Sys::Virt::Error>, C<http://libvirt.org>

=cut
