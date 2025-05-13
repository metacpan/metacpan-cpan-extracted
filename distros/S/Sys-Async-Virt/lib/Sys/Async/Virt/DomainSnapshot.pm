####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.3.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;

package Sys::Async::Virt::DomainSnapshot v0.0.19;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.19;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    XML_SECURE           => (1 << 0),
    LIST_ROOTS           => (1 << 0),
    LIST_DESCENDANTS     => (1 << 0),
    LIST_LEAVES          => (1 << 2),
    LIST_NO_LEAVES       => (1 << 3),
    LIST_METADATA        => (1 << 1),
    LIST_NO_METADATA     => (1 << 4),
    LIST_INACTIVE        => (1 << 5),
    LIST_ACTIVE          => (1 << 6),
    LIST_DISK_ONLY       => (1 << 7),
    LIST_INTERNAL        => (1 << 8),
    LIST_EXTERNAL        => (1 << 9),
    LIST_TOPOLOGICAL     => (1 << 10),
    REVERT_RUNNING       => 1 << 0,
    REVERT_PAUSED        => 1 << 1,
    REVERT_FORCE         => 1 << 2,
    REVERT_RESET_NVRAM   => 1 << 3,
    DELETE_CHILDREN      => (1 << 0),
    DELETE_METADATA_ONLY => (1 << 1),
    DELETE_CHILDREN_ONLY => (1 << 2),
};


sub new($class, %args) {
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

sub delete($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_DELETE,
        { snap => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

async sub get_parent($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_GET_PARENT,
        { snap => $self->{id}, flags => $flags // 0 }, unwrap => 'snap' );
}

async sub get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_GET_XML_DESC,
        { snap => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

async sub has_metadata($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_HAS_METADATA,
        { snap => $self->{id}, flags => $flags // 0 }, unwrap => 'metadata' );
}

async sub is_current($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_IS_CURRENT,
        { snap => $self->{id}, flags => $flags // 0 }, unwrap => 'current' );
}

async sub list_all_children($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_LIST_ALL_CHILDREN,
        { snapshot => $self->{id}, need_results => $remote->DOMAIN_SNAPSHOT_LIST_MAX, flags => $flags // 0 }, unwrap => 'snapshots' );
}

async sub list_children_names($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_LIST_CHILDREN_NAMES,
        { snap => $self->{id}, maxnames => $remote->DOMAIN_SNAPSHOT_LIST_MAX, flags => $flags // 0 }, unwrap => 'names' );
}

async sub num_children($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_NUM_CHILDREN,
        { snap => $self->{id}, flags => $flags // 0 }, unwrap => 'num' );
}

sub revert_to_snapshot($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_REVERT_TO_SNAPSHOT,
        { snap => $self->{id}, flags => $flags // 0 }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::DomainSnapshot - Client side proxy to remote LibVirt domain snapshot

=head1 VERSION

v0.0.19

=head1 SYNOPSIS

  use Future::AsyncAwait;

  my $domain = await $virt->domain_lookup_by_name( 'domain' );
  my $snap   = await $domain->snapshot_lookup_by_name( 'snap' );
  say await $snap->num_children;

=head1 DESCRIPTION

=head1 EVENTS

There are no (LibVirt) events available for snapshots.

=head1 CONSTRUCTOR

=head2 new

Not to be called directly. Various API calls return instances of this type.

=head1 METHODS

=head2 delete

  await $snapshot->delete( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSnapshotDelete|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotDelete>.


=head2 get_parent

  $snap = await $snapshot->get_parent( $flags = 0 );

See documentation of L<virDomainSnapshotGetParent|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotGetParent>.


=head2 get_xml_desc

  $xml = await $snapshot->get_xml_desc( $flags = 0 );

See documentation of L<virDomainSnapshotGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotGetXMLDesc>.


=head2 has_metadata

  $metadata = await $snapshot->has_metadata( $flags = 0 );

See documentation of L<virDomainSnapshotHasMetadata|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotHasMetadata>.


=head2 is_current

  $current = await $snapshot->is_current( $flags = 0 );

See documentation of L<virDomainSnapshotIsCurrent|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotIsCurrent>.


=head2 list_all_children

  $snapshots = await $snapshot->list_all_children( $flags = 0 );

See documentation of L<virDomainSnapshotListAllChildren|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotListAllChildren>.


=head2 list_children_names

  $names = await $snapshot->list_children_names( $flags = 0 );

See documentation of L<virDomainSnapshotListChildrenNames|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotListChildrenNames>.


=head2 num_children

  $num = await $snapshot->num_children( $flags = 0 );

See documentation of L<virDomainSnapshotNumChildren|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotNumChildren>.


=head2 revert_to_snapshot

  await $snapshot->revert_to_snapshot( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainRevertToSnapshot|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainRevertToSnapshot>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item XML_SECURE

=item LIST_ROOTS

=item LIST_DESCENDANTS

=item LIST_LEAVES

=item LIST_NO_LEAVES

=item LIST_METADATA

=item LIST_NO_METADATA

=item LIST_INACTIVE

=item LIST_ACTIVE

=item LIST_DISK_ONLY

=item LIST_INTERNAL

=item LIST_EXTERNAL

=item LIST_TOPOLOGICAL

=item REVERT_RUNNING

=item REVERT_PAUSED

=item REVERT_FORCE

=item REVERT_RESET_NVRAM

=item DELETE_CHILDREN

=item DELETE_METADATA_ONLY

=item DELETE_CHILDREN_ONLY

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
