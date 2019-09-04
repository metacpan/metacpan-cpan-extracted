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

Sys::Virt::DomainCheckpoint - Represent & manage a libvirt guest domain checkpoint

=head1 DESCRIPTION

The C<Sys::Virt::DomainCheckpoint> module represents a guest domain
checkpoint managed by the virtual machine monitor.

=head1 METHODS

=over 4

=cut

package Sys::Virt::DomainCheckpoint;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $dom = exists $params{domain} ? $params{domain} : die "domain parameter is required";
    my $self;
    if (exists $params{name}) {
	$self = Sys::Virt::DomainCheckpoint::_lookup_by_name($dom,  $params{name});
    } elsif (exists $params{xml}) {
	$self = Sys::Virt::DomainCheckpoint::_create_xml($dom,  $params{xml}, $params{flags} ? $params{flags} : 0);
    } else {
	die "name or xml parameters are required";
    }

    bless $self, $class;

    return $self;
}

=item my $str = $domchkp->get_name()

Return the name of the checkpoint

=item my $xml = $domchkp->get_xml_description($flags)

Returns an XML document containing a complete description of
the domain checkpoints' configuration. The C<$flags> parameter
accepts the following constants

=over 4

=item Sys::Virt::DomainCheckpoint::XML_SECURE

Include security sensitive information in the XML dump, such as
passwords.

=item Sys::Virt::DomainCheckpoint::XML_SIZE

Inlude dynamic per-<disk> size information

=item Sys::Virt::DomainCheckpoint::XML_NO_DOMAIN

Supress <domain> sub-element

=back

=item $domchkp->delete($flags)

Deletes this checkpoint object & its data. The optional C<$flags> parameter controls
what should be deleted via the C<Sys::Virt::DomainCheckpoint::DELETE_*>
constants.

=item $parentchkp = $domchkp->get_parent();

Return the parent of the checkpoint, if any

=item $res = $domchkp->has_metadata()

Returns a true value if this checkpoint has metadata associated with
it.

=item my @checkpoints = $domchkp->list_all_children($flags)

Return a list of all domain checkpoints that are children of this
checkpoint. The elements in the returned list are instances of the
L<Sys::Virt::DomainCheckpoint> class. The C<$flags> parameter can be
used to filter the list of return domain checkpoints.

=back

=head1 CONSTANTS

=head2 CHECKPOINT CREATION

The following constants are useful when creating checkpoints

=over 4

=item Sys::Virt::DomainCheckpoint::CREATE_REDEFINE

Replace/set the metadata with the checkpoint

=item Sys::Virt::DomainCheckpoint::CREATE_QUIESCE

Quiesce the guest disks while taking the checkpoint

=back

=head2 CHECKPOINT DELETION

The following constants are useful when deleting checkpoints

=over 4

=item Sys::Virt::DomainCheckpoint::DELETE_CHILDREN

Recursively delete any child checkpoints

=item Sys::Virt::DomainCheckpoint::DELETE_CHILDREN_ONLY

Only delete the child checkpoints

=item Sys::Virt::DomainCheckpoint::DELETE_METADATA_ONLY

Only delete the checkpoint metadata

=back

=head2 CHECKPOINT LIST

The following constants are useful when listing checkpoints

=over 4

=item Sys::Virt::DomainCheckpoint::LIST_ROOTS

Only list checkpoints which are root nodes in the tree

=item Sys::Virt::DomainCheckpoint::LIST_DESCENDANTS

Only list checkpoints which are descendants of the current
checkpoint

=item Sys::Virt::DomainCheckpoint::LIST_LEAVES

Only list leaf nodes in the checkpoint tree

=item Sys::Virt::DomainCheckpoint::LIST_NO_LEAVES

Only list non-leaf nodes in the checkpoint tree

=item Sys::Virt::DomainCheckpoint::LIST_TOPOLOGICAL

Sort list in topological order wrt to parent/child
relationships.

=back

=over 4

=cut

1;

=back

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
