####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v10.3.0
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

package Sys::Async::Virt::StoragePool v0.0.11;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.11;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    INACTIVE           => 0,
    BUILDING           => 1,
    RUNNING            => 2,
    DEGRADED           => 3,
    INACCESSIBLE       => 4,
    BUILD_NEW          => 0,
    BUILD_REPAIR       => (1 << 0),
    BUILD_RESIZE       => (1 << 1),
    BUILD_NO_OVERWRITE => (1 << 2),
    BUILD_OVERWRITE    => (1 << 3),
    DELETE_NORMAL      => 0,
    DELETE_ZEROED      => 1 << 0,
    XML_INACTIVE       => (1 << 0),
    EVENT_DEFINED      => 0,
    EVENT_UNDEFINED    => 1,
    EVENT_STARTED      => 2,
    EVENT_STOPPED      => 3,
    EVENT_CREATED      => 4,
    EVENT_DELETED      => 5,
};


sub new($class, %args) {
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

sub build($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_BUILD,
        { pool => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub create($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_CREATE,
        { pool => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub delete($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_DELETE,
        { pool => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub destroy($self) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_DESTROY,
        { pool => $self->{id} }, empty => 1 );
}

async sub get_autostart($self) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_GET_AUTOSTART,
        { pool => $self->{id} }, unwrap => 'autostart' );
}

sub get_info($self) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_GET_INFO,
        { pool => $self->{id} } );
}

async sub get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_GET_XML_DESC,
        { pool => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

async sub is_active($self) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_IS_ACTIVE,
        { pool => $self->{id} }, unwrap => 'active' );
}

async sub is_persistent($self) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_IS_PERSISTENT,
        { pool => $self->{id} }, unwrap => 'persistent' );
}

async sub list_all_volumes($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_LIST_ALL_VOLUMES,
        { pool => $self->{id}, need_results => $remote->STORAGE_VOL_LIST_MAX, flags => $flags // 0 }, unwrap => 'vols' );
}

async sub list_volumes($self) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_LIST_VOLUMES,
        { pool => $self->{id}, maxnames => $remote->STORAGE_VOL_LIST_MAX }, unwrap => 'names' );
}

async sub num_of_volumes($self) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_NUM_OF_VOLUMES,
        { pool => $self->{id} }, unwrap => 'num' );
}

sub refresh($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_REFRESH,
        { pool => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub set_autostart($self, $autostart) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_SET_AUTOSTART,
        { pool => $self->{id}, autostart => $autostart }, empty => 1 );
}

sub undefine($self) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_UNDEFINE,
        { pool => $self->{id} }, empty => 1 );
}

async sub vol_create_xml($self, $xml, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_CREATE_XML,
        { pool => $self->{id}, xml => $xml, flags => $flags // 0 }, unwrap => 'vol' );
}

async sub vol_create_xml_from($self, $xml, $clonevol, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_CREATE_XML_FROM,
        { pool => $self->{id}, xml => $xml, clonevol => $clonevol, flags => $flags // 0 }, unwrap => 'vol' );
}

async sub vol_lookup_by_name($self, $name) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_LOOKUP_BY_NAME,
        { pool => $self->{id}, name => $name }, unwrap => 'vol' );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::StoragePool - Client side proxy to remote LibVirt storage pool

=head1 VERSION

v0.0.11

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 build

  await $pool->build( $flags = 0 );
  # -> (* no data *)

See documentation of L<virStoragePoolBuild|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolBuild>.


=head2 create

  await $pool->create( $flags = 0 );
  # -> (* no data *)

See documentation of L<virStoragePoolCreate|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolCreate>.


=head2 delete

  await $pool->delete( $flags = 0 );
  # -> (* no data *)

See documentation of L<virStoragePoolDelete|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolDelete>.


=head2 destroy

  await $pool->destroy;
  # -> (* no data *)

See documentation of L<virStoragePoolDestroy|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolDestroy>.


=head2 get_autostart

  $autostart = await $pool->get_autostart;

See documentation of L<virStoragePoolGetAutostart|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolGetAutostart>.


=head2 get_info

  await $pool->get_info;
  # -> { allocation => $allocation,
  #      available => $available,
  #      capacity => $capacity,
  #      state => $state }

See documentation of L<virStoragePoolGetInfo|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolGetInfo>.


=head2 get_xml_desc

  $xml = await $pool->get_xml_desc( $flags = 0 );

See documentation of L<virStoragePoolGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolGetXMLDesc>.


=head2 is_active

  $active = await $pool->is_active;

See documentation of L<virStoragePoolIsActive|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolIsActive>.


=head2 is_persistent

  $persistent = await $pool->is_persistent;

See documentation of L<virStoragePoolIsPersistent|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolIsPersistent>.


=head2 list_all_volumes

  $vols = await $pool->list_all_volumes( $flags = 0 );

See documentation of L<virStoragePoolListAllVolumes|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolListAllVolumes>.


=head2 list_volumes

  $names = await $pool->list_volumes;

See documentation of L<virStoragePoolListVolumes|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolListVolumes>.


=head2 num_of_volumes

  $num = await $pool->num_of_volumes;

See documentation of L<virStoragePoolNumOfVolumes|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolNumOfVolumes>.


=head2 refresh

  await $pool->refresh( $flags = 0 );
  # -> (* no data *)

See documentation of L<virStoragePoolRefresh|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolRefresh>.


=head2 set_autostart

  await $pool->set_autostart( $autostart );
  # -> (* no data *)

See documentation of L<virStoragePoolSetAutostart|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolSetAutostart>.


=head2 undefine

  await $pool->undefine;
  # -> (* no data *)

See documentation of L<virStoragePoolUndefine|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolUndefine>.


=head2 vol_create_xml

  $vol = await $pool->vol_create_xml( $xml, $flags = 0 );

See documentation of L<virStorageVolCreateXML|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolCreateXML>.


=head2 vol_create_xml_from

  $vol = await $pool->vol_create_xml_from( $xml, $clonevol, $flags = 0 );

See documentation of L<virStorageVolCreateXMLFrom|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolCreateXMLFrom>.


=head2 vol_lookup_by_name

  $vol = await $pool->vol_lookup_by_name( $name );

See documentation of L<virStorageVolLookupByName|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolLookupByName>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item INACTIVE

=item BUILDING

=item RUNNING

=item DEGRADED

=item INACCESSIBLE

=item BUILD_NEW

=item BUILD_REPAIR

=item BUILD_RESIZE

=item BUILD_NO_OVERWRITE

=item BUILD_OVERWRITE

=item DELETE_NORMAL

=item DELETE_ZEROED

=item XML_INACTIVE

=item EVENT_DEFINED

=item EVENT_UNDEFINED

=item EVENT_STARTED

=item EVENT_STOPPED

=item EVENT_CREATED

=item EVENT_DELETED

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.