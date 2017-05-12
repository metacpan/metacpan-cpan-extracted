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

Sys::Virt::StorageVol - Represent & manage a libvirt storage volume

=head1 DESCRIPTION

The C<Sys::Virt::StorageVol> module represents a storage volume managed
by libvirt. A storage volume is always associated with a containing
storage pool (C<Sys::Virt::StoragePool>).

=head1 METHODS

=over 4

=cut

package Sys::Virt::StorageVol;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $self;
    if (exists $params{name}) {
	my $pool = exists $params{pool} ? $params{pool} : die "pool parameter is requried";
	$self = Sys::Virt::StorageVol::_lookup_by_name($pool,  $params{name});
    } elsif (exists $params{key}) {
	my $con = exists $params{connection} ? $params{connection} : die "connection parameter is requried";
	$self = Sys::Virt::StorageVol::_lookup_by_key($con,  $params{key});
    } elsif (exists $params{path}) {
	my $con = exists $params{connection} ? $params{connection} : die "connection parameter is requried";
	$self = Sys::Virt::StorageVol::_lookup_by_path($con,  $params{path});
    } elsif (exists $params{xml}) {
	my $pool = exists $params{pool} ? $params{pool} : die "pool parameter is requried";
	if ($params{clone}) {
	    $self = Sys::Virt::StorageVol::_create_xml_from($pool,  $params{xml}, $params{clone}, 0);
	} else {
	    $self = Sys::Virt::StorageVol::_create_xml($pool,  $params{xml}, 0);
	}
    } else {
	die "name, key, path or xml parameters are required";
    }

    bless $self, $class;

    return $self;
}


=item my $name = $vol->get_name()

Returns a string with a locally unique name of the storage vol

=item my $name = $vol->get_key()

Returns a string with a globally unique key for the storage vol

=item my $name = $vol->get_path()

Returns a string with a locally unique file path of the storage vol

=item my $xml = $vol->get_xml_description()

Returns an XML document containing a complete description of
the storage vol's configuration

=item $vol->delete($flags)

Immediately delete the storage volume freeing its storage resources.
The C<flags> parameter indicates any special action to be taken when
deleting the volume.

=item $vol->resize($newcapacity, $flags=0)

Adjust the size of the storage volume. The C<$newcapacity> value
semantics depend on the C<$flags> parameter. If C<$flags>
specifies C<RESIZE_DELTA> then the C<$newcapacity> is relative
to the current size. If C<$flags> specifies C<RESIZE_SHRINK>
then the C<$newcapacity> value is the amount of space to remove

=item $vol->wipe($flags = 0)

Clear the data in the storage volume to avoid future information
leak. The C<flags> parameter is currently unused and defaults
to zero.

=item $vol->wipe_pattern($algorithm, $flags = 0)

Clear the data in the storage volume to avoid future information
leak. The C<$algorithm> parameter specifies the data pattern used
to erase data, and should be one of the WIPE ALGORITHM CONSTANTS
listed later. The C<flags> parameter is currently unused and defaults
to zero.

=item my $info = $vol->get_info($flags = 0)

Retrieve live information about the storage volume. The returned
C<$info> hash reference contains three keys. C<type> indicates whether
the volume is a file or block device. C<capacity> provides the maximum
logical size of the volume. C<allocation> provides the current
physical usage of the volume. The allocation may be less than the
capacity for sparse, or grow-on-demand volumes. The allocation
may also be larger than the capacity, if there is a metadata overhead
for the volume format. C<$flags> may take one of the values

=over 4

=item Sys::Virt::StorageVol::USE_ALLOCATION

Return the current allocation in allocation

=item Sys::Virt::StorageVol::GET_PHYSICAL

Return the physical size in allocation

=back

=item $vol->download($st, $offset, $length);

Download data from C<$vol> using the stream C<$st>. If C<$offset>
and C<$length> are non-zero, then restrict data to the specified
volume byte range.

=item $vol->upload($st, $offset, $length);

Upload data to C<$vol> using the stream C<$st>. If C<$offset>
and C<$length> are non-zero, then restrict data to the specified
volume byte range.

=back

=head1 CONSTANTS

The following sets of constants are useful when dealing with storage
volumes

=head2 VOLUME TYPES

The following constants are useful for interpreting the C<type>
field in the hash returned by the C<get_info> method

=over 4

=item Sys::Virt::StorageVol::TYPE_FILE

The volume is a plain file

=item Sys::Virt::StorageVol::TYPE_BLOCK

The volume is a block device

=item Sys::Virt::StorageVol::TYPE_DIR

The volume is a directory

=item Sys::Virt::StorageVol::TYPE_NETWORK

The volume is a network source

=item Sys::Virt::StorageVol::TYPE_NETDIR

The volume is a network directory

=item Sys::Virt::StorageVol::TYPE_PLOOP

The volume is a ploop directory

=back

=head2 CREATE MODES

The following constants are useful for the C<flags> parameter of
the C<create> method

=over 4

=item Sys::Virt::StorageVol::CREATE_PREALLOC_METADATA

Preallocate header metadata when creating the volume.

=item Sys::Virt::StorageVol::CREATE_REFLINK

Perform lightweight reference copy

=back

=head2 DELETE MODES

The following constants are useful for the C<flags> parameter of
the C<delete> method

=over 4

=item Sys::Virt::StorageVol::DELETE_NORMAL

Do a plain delete without any attempt to scrub data.

=item Sys::Virt::StorageVol::DELETE_ZEROED

Zero out current allocated blocks when deleteing the volume

=item Sys::Virt::StorageVol::DELETE_WITH_SNAPSHOTS

Delete snapshots associated with the volume

=back

=head2 WIPE ALGORITHM CONSTANTS

The following constants specify the algorithm for erasing
data

=over 4

=item Sys::Virt::StorageVol::WIPE_ALG_BSI

9-pass method recommended by the German Center
of Security in Information Technologies

=item Sys::Virt::StorageVol::WIPE_ALG_DOD

4-pass Dod 5220.22-M section, 8-306 procedure

=item Sys::Virt::StorageVol::WIPE_ALG_GUTMANN

The canonical 35-pass sequence

=item Sys::Virt::StorageVol::WIPE_ALG_NNSA

4-pass NNSA Policy Letter NAP-14.1-C (XVI-8)

=item Sys::Virt::StorageVol::WIPE_ALG_PFITZNER7

7-pass random

=item Sys::Virt::StorageVol::WIPE_ALG_PFITZNER33

33-pass random

=item Sys::Virt::StorageVol::WIPE_ALG_RANDOM

1-pass random

=item Sys::Virt::StorageVol::WIPE_ALG_SCHNEIER

7-pass method described by Bruce Schneier in "Applied
Cryptography" (1996)

=item Sys::Virt::StorageVol::WIPE_ALG_ZERO

1-pass, all zeroes

=item Sys::Virt::StorageVol::WIPE_ALG_TRIM

1-pass, trim all data on the volume by using TRIM or DISCARD

=back

VOLUME RESIZE CONSTANTS

The following constants control how storage volumes can
be resized

=over 4

=item Sys::Virt::StorageVol::RESIZE_ALLOCATE

Fully allocate the extra space required during resize

=item Sys::Virt::StorageVol::RESIZE_DELTA

Treat the new capacity as a delta to the current capacity

=item Sys::Virt::StorageVol::RESIZE_SHRINK

Treat the new capacity as an amount to remove from the capacity

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
