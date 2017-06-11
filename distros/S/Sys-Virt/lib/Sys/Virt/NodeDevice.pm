# -*- perl -*-
#
# Copyright (C) 2006-2009 Red Hat
# Copyright (C) 2006-2009 Daniel P. Berrange
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

Sys::Virt::NodeDevice - Represent & manage a libvirt storage pool

=head1 DESCRIPTION

The C<Sys::Virt::NodeDevice> module represents a storage pool managed
by libvirt. There are a variety of storage pool implementations for
LVM, Local directories/filesystems, network filesystems, disk
partitioning, iSCSI, and SCSI.

=head1 METHODS

=over 4

=cut

package Sys::Virt::NodeDevice;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $con = exists $params{connection} ? $params{connection} : die "connection parameter is requried";
    my $self;
    if (exists $params{name}) {
	$self = Sys::Virt::NodeDevice::_lookup_by_name($con,  $params{name});
    } elsif (exists $params{wwnn}) {
	$self = Sys::Virt::NodeDevice::_lookup_scsihost_by_wwn($con,
							       $params{wwnn},
							       $params{wwpn},
							       $params{flags});
    } elsif (exists $params{xml}) {
	$self = Sys::Virt::NodeDevice::_create_xml($con, $params{xml});
    } else {
	die "name parameter is required";
    }

    bless $self, $class;

    return $self;
}


=item my $name = $dev->get_name()

Returns a string with a locally unique name of the device

=item my $parentname = $dev->get_parent()

Returns a string with a locally unique name of the parent
of the device, or undef if there is no parent

=item my $xml = $dev->get_xml_description()

Returns an XML document containing a complete description of
the storage dev's configuration

=item $dev->reattach()

Rebind the node device to the host OS device drivers.

=item $dev->dettach()

Unbind the node device from the host OS device driver

=item $dev->reset()

Reset the node device. The device must be unbound from the host
OS drivers for this to work

=item $dev->destroy()

Destroy the virtual device releasing any OS resources associated
with it.

=item my @caps = $dev->list_capabilities()

Return a list of all capabilities in the device.

=back

=head1 CONSTANTS

This section documents constants that are used with various
APIs described above

=head2 LIST FILTERING

The following constants are used to filter object lists

=over 4

=item Sys::Virt::NodeDevice::LIST_CAP_NET

Include devices with the network capability

=item Sys::Virt::NodeDevice::LIST_CAP_PCI_DEV

Include devices with the PCI device capability

=item Sys::Virt::NodeDevice::LIST_CAP_SCSI

Include devices with the SCSI capability

=item Sys::Virt::NodeDevice::LIST_CAP_SCSI_HOST

Include devices with the SCSI host capability

=item Sys::Virt::NodeDevice::LIST_CAP_SCSI_TARGET

Include devices with the SCSI target capability

=item Sys::Virt::NodeDevice::LIST_CAP_STORAGE

Include devices with the storage capability

=item Sys::Virt::NodeDevice::LIST_CAP_SYSTEM

Include devices with the system capability

=item Sys::Virt::NodeDevice::LIST_CAP_USB_DEV

Include devices with the USB device capability

=item Sys::Virt::NodeDevice::LIST_CAP_USB_INTERFACE

Include devices with the USB interface capability

=item Sys::Virt::NodeDevice::LIST_CAP_FC_HOST

Include devices with the fibre channel host capability

=item Sys::Virt::NodeDevice::LIST_CAP_VPORTS

Include devices with the NPIV vport capability

=item Sys::Virt::NodeDevice::LIST_CAP_SCSI_GENERIC

Include devices with the SCSI generic capability

=item Sys::Virt::NodeDevice::LIST_CAP_DRM

Include devices with the DRM capability

=item Sys::Virt::NodeDevice::LIST_CAP_MDEV

Include mediated devices

=item Sys::Virt::NodeDevice::LIST_CAP_MDEV_TYPES

Include devices capable of mediated devices

=item Sys::Virt::NodeDevice::LIST_CAP_CCW_DEV

Include CCW devices

=back

=head2 EVENT ID CONSTANTS

=over 4

=item Sys::Virt::NodeDevice::EVENT_ID_LIFECYCLE

Node device lifecycle events

=item Sys::Virt::NodeDevice::EVENT_ID_UPDATE

Node device config update events

=back

=head2 LIFECYCLE CHANGE EVENTS

The following constants allow node device lifecycle change events to be
interpreted. The events contain both a state change, and a
reason though the reason is currently unsed.

=over 4

=item Sys::Virt::NodeDevice::EVENT_CREATED

Indicates that a device was created

=item Sys::Virt::NodeDevice::EVENT_DELETED

Indicates that a device has been deleted

=back

=cut


1;

=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2006-2009 Red Hat
Copyright (C) 2006-2009 Daniel P. Berrange

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt>, L<Sys::Virt::Error>, C<http://libvirt.org>

=cut
