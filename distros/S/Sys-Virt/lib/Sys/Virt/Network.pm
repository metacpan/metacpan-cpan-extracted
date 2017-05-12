# -*- perl -*-
#
# Copyright (C) 2006 Red Hat
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

Sys::Virt::Network - Represent & manage a libvirt virtual network

=head1 DESCRIPTION

The C<Sys::Virt::Network> module represents a virtual network managed
by the virtual machine monitor.

=head1 METHODS

=over 4

=cut

package Sys::Virt::Network;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $con = exists $params{connection} ? $params{connection} : die "connection parameter is requried";
    my $self;
    if (exists $params{name}) {
	$self = Sys::Virt::Network::_lookup_by_name($con,  $params{name});
    } elsif (exists $params{uuid}) {
	if (length($params{uuid}) == 16) {
	    $self = Sys::Virt::Network::_lookup_by_uuid($con,  $params{uuid});
	} elsif (length($params{uuid}) == 32 ||
		 length($params{uuid}) == 36) {
	    $self = Sys::Virt::Network::_lookup_by_uuid_string($con,  $params{uuid});
	} else {
	    die "UUID must be either 16 unsigned bytes, or 32/36 hex characters long";
	}
    } elsif (exists $params{xml}) {
	if ($params{nocreate}) {
	    $self = Sys::Virt::Network::_define_xml($con,  $params{xml});
	} else {
	    $self = Sys::Virt::Network::_create_xml($con,  $params{xml});
	}
    } else {
	die "address, id or uuid parameters are required";
    }

    bless $self, $class;

    return $self;
}


=item my $uuid = $net->get_uuid()

Returns a 16 byte long string containing the raw globally unique identifier
(UUID) for the network.

=item my $uuid = $net->get_uuid_string()

Returns a printable string representation of the raw UUID, in the format
'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'.

=item my $name = $net->get_name()

Returns a string with a locally unique name of the network

=item $net->is_active()

Returns a true value if the network is currently running

=item $net->is_persistent()

Returns a true value if the network has a persistent configuration
file defined

=item my $xml = $net->get_xml_description()

Returns an XML document containing a complete description of
the network's configuration

=item $net->create()

Start a network whose configuration was previously defined using the
C<define_network> method in L<Sys::Virt>.

=item $net->undefine()

Remove the configuration associated with a network previously defined
with the C<define_network> method in L<Sys::Virt>. If the network is
running, you probably want to use the C<shutdown> or C<destroy>
methods instead.

=item $net->destroy()

Immediately terminate the machine, and remove it from the virtual
machine monitor. The C<$net> handle is invalid after this call
completes and should not be used again.

=item $net->update($command, $section, $parentIndex, $xml, $flags=0)

Update the network configuration with C<$xml>. The C<$section> parameter,
which must be one of the XML SECTION CONSTANTS listed later, indicates
what schema is used in C<$xml>. The C<$command> parameter determines
what action is taken. Finally, the C<$flags> parameter can be use to
control which config is affected.

=item $net->get_bridge_name()

Return the name of the bridge device associated with the virtual
network

=item $flag = $net->get_autostart();

Return a true value if the virtual network is configured to automatically
start upon boot. Return false, otherwise

=item $net->set_autostart($flag)

Set the state of the autostart flag, which determines whether the
virtual network will automatically start upon boot of the host OS.

=item @leases = $net->get_dhcp_leases($mac=undef, $flags=0)

Get a list of all active DHCP leases. If C<$mac> is undefined than
leases for all VMs are returned, otherwise only leases for the
matching MAC address are returned. The C<$flags> parameter is
currently unused and defaults to zero.

The elements in the returned array are hash references with
the following fields

=over 4

=item C<iface>

Network interface name

=item C<expirytime>

Seconds since the epoch until the lease expires

=item C<type>

One of the Sys::Virt IP address type constants

=item C<mac>

The MAC address of the lease

=item C<iaid>

The IAID of the client

=item C<ipaddr>

The IP address of the lease

=item C<prefix>

The IP address prefix

=item C<hostname>

The optional hostname associated with the lease

=item C<clientid>

The client ID or DUID

=back

=back

=head1 CONSTANTS

This section documents constants that are used with various
APIs described above

=head2 LIST FILTERING

The following constants are used to filter object lists

=over 4

=item Sys::Virt::Network::LIST_ACTIVE

Include networks which are active

=item Sys::Virt::Network::LIST_INACTIVE

Include networks which are not active

=item Sys::Virt::Network::LIST_AUTOSTART

Include networks which are set to autostart

=item Sys::Virt::Network::LIST_NO_AUTOSTART

Include networks which are not set to autostart

=item Sys::Virt::Network::LIST_PERSISTENT

Include networks which are persistent

=item Sys::Virt::Network::LIST_TRANSIENT

Include networks which are transient

=back

=head2 XML CONSTANTS

The following constants are used when querying XML

=over 4

=item Sys::Virt::Network::XML_INACTIVE

Request the inactive XML, instead of the current possibly live config.

=back

=head1 XML SECTION CONSTANTS

The following constants are used to refer to sections
of the XML document

=over 4

=item Sys::Virt::Network::SECTION_BRIDGE

The bridge device element

=item Sys::Virt::Network::SECTION_DNS_HOST

The DNS host record section

=item Sys::Virt::Network::SECTION_DNS_SRV

The DNS SRV record section

=item Sys::Virt::Network::SECTION_DNS_TXT

The DNS TXT record section

=item Sys::Virt::Network::SECTION_DOMAIN

The domain name section

=item Sys::Virt::Network::SECTION_FORWARD

The forward device section

=item Sys::Virt::Network::SECTION_FORWARD_INTERFACE

The forward interface section

=item Sys::Virt::Network::SECTION_FORWARD_PF

The forward physical function section

=item Sys::Virt::Network::SECTION_IP

The IP address section

=item Sys::Virt::Network::SECTION_IP_DHCP_HOST

The IP address DHCP host section

=item Sys::Virt::Network::SECTION_IP_DHCP_RANGE

The IP address DHCP range section

=item Sys::Virt::Network::SECTION_PORTGROUP

The port group section

=item Sys::Virt::Network::SECTION_NONE

The top level domain element

=back

=head2 XML UPDATE FLAGS

=over 4

=item Sys::Virt::Network::UPDATE_AFFECT_CURRENT

Affect whatever the current object state is

=item Sys::Virt::Network::UPDATE_AFFECT_CONFIG

Always update the config file

=item Sys::Virt::Network::UPDATE_AFFECT_LIVE

Always update the live config

=back

=head2 XML UPDATE COMMANDS

=over 4

=item Sys::Virt::Network::UPDATE_COMMAND_NONE

No update

=item Sys::Virt::Network::UPDATE_COMMAND_DELETE

Remove the matching entry

=item Sys::Virt::Network::UPDATE_COMMAND_MODIFY

Modify the matching entry

=item Sys::Virt::Network::UPDATE_COMMAND_ADD_FIRST

Insert the matching entry at the start

=item Sys::Virt::Network::UPDATE_COMMAND_ADD_LAST

Insert the matching entry at the end

=back

=head2 EVENT ID CONSTANTS

=over 4

=item Sys::Virt::Network::EVENT_ID_LIFECYCLE

Network lifecycle events

=back

=head2 LIFECYCLE CHANGE EVENTS

The following constants allow network lifecycle change events to be
interpreted. The events contain both a state change, and a
reason though the reason is currently unsed.

=over 4

=item Sys::Virt::Network::EVENT_DEFINED

Indicates that a persistent configuration has been defined for
the network.

=item Sys::Virt::Network::EVENT_STARTED

The network has started running

=item Sys::Virt::Network::EVENT_STOPPED

The network has stopped running

=item Sys::Virt::Network::EVENT_UNDEFINED

The persistent configuration has gone away

=back


=cut


1;


=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2006 Red Hat
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
