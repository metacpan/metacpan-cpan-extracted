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

package Sys::Async::Virt::StorageVol v0.0.7;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.7;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    FILE                   => 0,
    BLOCK                  => 1,
    DIR                    => 2,
    NETWORK                => 3,
    NETDIR                 => 4,
    PLOOP                  => 5,
    DELETE_NORMAL          => 0,
    DELETE_ZEROED          => 1 << 0,
    DELETE_WITH_SNAPSHOTS  => 1 << 1,
    WIPE_ALG_ZERO          => 0,
    WIPE_ALG_NNSA          => 1,
    WIPE_ALG_DOD           => 2,
    WIPE_ALG_BSI           => 3,
    WIPE_ALG_GUTMANN       => 4,
    WIPE_ALG_SCHNEIER      => 5,
    WIPE_ALG_PFITZNER7     => 6,
    WIPE_ALG_PFITZNER33    => 7,
    WIPE_ALG_RANDOM        => 8,
    WIPE_ALG_TRIM          => 9,
    USE_ALLOCATION         => 0,
    GET_PHYSICAL           => 1 << 0,
    DOWNLOAD_SPARSE_STREAM => 1 << 0,
    UPLOAD_SPARSE_STREAM   => 1 << 0,
    RESIZE_ALLOCATE        => 1 << 0,
    RESIZE_DELTA           => 1 << 1,
    RESIZE_SHRINK          => 1 << 2,
};


sub new($class, %args) {
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

sub delete($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_DELETE,
        { vol => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub download($self, $offset, $length, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_DOWNLOAD,
        { vol => $self->{id}, offset => $offset, length => $length, flags => $flags // 0 }, stream => 'read', empty => 1 );
}

sub get_info($self) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_GET_INFO,
        { vol => $self->{id} } );
}

async sub get_path($self) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_GET_PATH,
        { vol => $self->{id} }, unwrap => 'name' );
}

async sub get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_GET_XML_DESC,
        { vol => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

async sub pool_lookup_by_volume($self) {
    return await $self->{client}->_call(
        $remote->PROC_STORAGE_POOL_LOOKUP_BY_VOLUME,
        { vol => $self->{id} }, unwrap => 'pool' );
}

sub resize($self, $capacity, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_RESIZE,
        { vol => $self->{id}, capacity => $capacity, flags => $flags // 0 }, empty => 1 );
}

sub upload($self, $offset, $length, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_UPLOAD,
        { vol => $self->{id}, offset => $offset, length => $length, flags => $flags // 0 }, stream => 'write', empty => 1 );
}

sub wipe($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_WIPE,
        { vol => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub wipe_pattern($self, $algorithm, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_STORAGE_VOL_WIPE_PATTERN,
        { vol => $self->{id}, algorithm => $algorithm, flags => $flags // 0 }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::StorageVol - Client side proxy to remote LibVirt storage volume

=head1 VERSION

v0.0.7

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 delete

  await $vol->delete( $flags = 0 );
  # -> (* no data *)

See documentation of L<virStorageVolDelete|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolDelete>.


=head2 download

  $stream = await $vol->download( $offset, $length, $flags = 0 );

See documentation of L<virStorageVolDownload|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolDownload>.


=head2 get_info

  await $vol->get_info;
  # -> { allocation => $allocation,
  #      capacity => $capacity,
  #      type => $type }

See documentation of L<virStorageVolGetInfo|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolGetInfo>.


=head2 get_path

  $name = await $vol->get_path;

See documentation of L<virStorageVolGetPath|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolGetPath>.


=head2 get_xml_desc

  $xml = await $vol->get_xml_desc( $flags = 0 );

See documentation of L<virStorageVolGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolGetXMLDesc>.


=head2 pool_lookup_by_volume

  $pool = await $vol->pool_lookup_by_volume;

See documentation of L<virStoragePoolLookupByVolume|https://libvirt.org/html/libvirt-libvirt-storage.html#virStoragePoolLookupByVolume>.


=head2 resize

  await $vol->resize( $capacity, $flags = 0 );
  # -> (* no data *)

See documentation of L<virStorageVolResize|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolResize>.


=head2 upload

  $stream = await $vol->upload( $offset, $length, $flags = 0 );

See documentation of L<virStorageVolUpload|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolUpload>.


=head2 wipe

  await $vol->wipe( $flags = 0 );
  # -> (* no data *)

See documentation of L<virStorageVolWipe|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolWipe>.


=head2 wipe_pattern

  await $vol->wipe_pattern( $algorithm, $flags = 0 );
  # -> (* no data *)

See documentation of L<virStorageVolWipePattern|https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageVolWipePattern>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item FILE

=item BLOCK

=item DIR

=item NETWORK

=item NETDIR

=item PLOOP

=item DELETE_NORMAL

=item DELETE_ZEROED

=item DELETE_WITH_SNAPSHOTS

=item WIPE_ALG_ZERO

=item WIPE_ALG_NNSA

=item WIPE_ALG_DOD

=item WIPE_ALG_BSI

=item WIPE_ALG_GUTMANN

=item WIPE_ALG_SCHNEIER

=item WIPE_ALG_PFITZNER7

=item WIPE_ALG_PFITZNER33

=item WIPE_ALG_RANDOM

=item WIPE_ALG_TRIM

=item USE_ALLOCATION

=item GET_PHYSICAL

=item DOWNLOAD_SPARSE_STREAM

=item UPLOAD_SPARSE_STREAM

=item RESIZE_ALLOCATE

=item RESIZE_DELTA

=item RESIZE_SHRINK

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.