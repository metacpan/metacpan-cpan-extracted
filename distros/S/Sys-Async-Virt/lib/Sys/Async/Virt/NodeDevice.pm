####################################################################
#
#     This file was generated using XDR::Parse version v1.0.1
#                   and LibVirt version v12.5.0
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
use Object::Pad;

class Sys::Async::Virt::NodeDevice v0.6.5;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v12.5.0;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    XML_INACTIVE          => 1 << 0,
    UPDATE_AFFECT_CURRENT => 0,
    UPDATE_AFFECT_LIVE    => 1 << 0,
    UPDATE_AFFECT_CONFIG  => 1 << 1,
    EVENT_CREATED         => 0,
    EVENT_DELETED         => 1,
    EVENT_DEFINED         => 2,
    EVENT_UNDEFINED       => 3,
};


field $_rpc_id :param :reader;
field $_client :param :reader;

method name() {
    return $_rpc_id->{name};
}


method create($flags = 0) {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_CREATE,
        { name => $_rpc_id, flags => $flags // 0 }, empty => 1 );
}

async method create_xml($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_CREATE_XML,
        { xml_desc => $_rpc_id, flags => $flags // 0 }, unwrap => 'dev' );
}

async method define_xml($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_DEFINE_XML,
        { xml_desc => $_rpc_id, flags => $flags // 0 }, unwrap => 'dev' );
}

method destroy() {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_DESTROY,
        { name => $_rpc_id }, empty => 1 );
}

method detach_flags($driverName, $flags = 0) {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_DETACH_FLAGS,
        { name => $_rpc_id, driverName => $driverName, flags => $flags // 0 }, empty => 1 );
}

method dettach() {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_DETTACH,
        { name => $_rpc_id }, empty => 1 );
}

async method get_autostart() {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_GET_AUTOSTART,
        { name => $_rpc_id }, unwrap => 'autostart' );
}

async method get_parent() {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_GET_PARENT,
        { name => $_rpc_id }, unwrap => 'parentName' );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_GET_XML_DESC,
        { name => $_rpc_id, flags => $flags // 0 }, unwrap => 'xml' );
}

async method is_active() {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_IS_ACTIVE,
        { name => $_rpc_id }, unwrap => 'active' );
}

async method is_persistent() {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_IS_PERSISTENT,
        { name => $_rpc_id }, unwrap => 'persistent' );
}

async method list_caps() {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_LIST_CAPS,
        { name => $_rpc_id, maxnames => $remote->NODE_DEVICE_CAPS_LIST_MAX }, unwrap => 'names' );
}

async method lookup_by_name() {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_LOOKUP_BY_NAME,
        { name => $_rpc_id }, unwrap => 'dev' );
}

async method lookup_scsi_host_by_wwn($wwpn, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_LOOKUP_SCSI_HOST_BY_WWN,
        { wwnn => $_rpc_id, wwpn => $wwpn, flags => $flags // 0 }, unwrap => 'dev' );
}

async method num_of_caps() {
    return await $_client->_call(
        $remote->PROC_NODE_DEVICE_NUM_OF_CAPS,
        { name => $_rpc_id }, unwrap => 'num' );
}

method reattach() {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_RE_ATTACH,
        { name => $_rpc_id }, empty => 1 );
}

method reset() {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_RESET,
        { name => $_rpc_id }, empty => 1 );
}

method set_autostart($autostart) {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_SET_AUTOSTART,
        { name => $_rpc_id, autostart => $autostart }, empty => 1 );
}

method undefine($flags = 0) {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_UNDEFINE,
        { name => $_rpc_id, flags => $flags // 0 }, empty => 1 );
}

method update($xml_desc, $flags = 0) {
    return $_client->_call(
        $remote->PROC_NODE_DEVICE_UPDATE,
        { name => $_rpc_id, xml_desc => $xml_desc, flags => $flags // 0 }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::NodeDevice - Client side proxy to remote LibVirt host device

=head1 VERSION

v0.6.5

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 name

  $name = $dev->name;

Returns the name of the device.

=head2 create

  await $dev->create( $flags = 0 );
  # -> (* no data *)

See documentation of L<virNodeDeviceCreate|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceCreate>.


=head2 create_xml

  $dev = await $dev->create_xml( $flags = 0 );

See documentation of L<virNodeDeviceCreateXML|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceCreateXML>.


=head2 define_xml

  $dev = await $dev->define_xml( $flags = 0 );

See documentation of L<virNodeDeviceDefineXML|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceDefineXML>.


=head2 destroy

  await $dev->destroy;
  # -> (* no data *)

See documentation of L<virNodeDeviceDestroy|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceDestroy>.


=head2 detach_flags

  await $dev->detach_flags( $driverName, $flags = 0 );
  # -> (* no data *)

See documentation of L<virNodeDeviceDetachFlags|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceDetachFlags>.


=head2 dettach

  await $dev->dettach;
  # -> (* no data *)

See documentation of L<virNodeDeviceDettach|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceDettach>.


=head2 get_autostart

  $autostart = await $dev->get_autostart;

See documentation of L<virNodeDeviceGetAutostart|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceGetAutostart>.


=head2 get_parent

  $parentName = await $dev->get_parent;

See documentation of L<virNodeDeviceGetParent|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceGetParent>.


=head2 get_xml_desc

  $xml = await $dev->get_xml_desc( $flags = 0 );

See documentation of L<virNodeDeviceGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceGetXMLDesc>.


=head2 is_active

  $active = await $dev->is_active;

See documentation of L<virNodeDeviceIsActive|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceIsActive>.


=head2 is_persistent

  $persistent = await $dev->is_persistent;

See documentation of L<virNodeDeviceIsPersistent|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceIsPersistent>.


=head2 list_caps

  $names = await $dev->list_caps;

See documentation of L<virNodeDeviceListCaps|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceListCaps>.


=head2 lookup_by_name

  $dev = await $dev->lookup_by_name;

See documentation of L<virNodeDeviceLookupByName|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceLookupByName>.


=head2 lookup_scsi_host_by_wwn

  $dev = await $dev->lookup_scsi_host_by_wwn( $wwpn, $flags = 0 );

See documentation of L<virNodeDeviceLookupSCSIHostByWWN|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceLookupSCSIHostByWWN>.


=head2 num_of_caps

  $num = await $dev->num_of_caps;

See documentation of L<virNodeDeviceNumOfCaps|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceNumOfCaps>.


=head2 reattach

  await $dev->reattach;
  # -> (* no data *)

See documentation of L<virNodeDeviceReAttach|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceReAttach>.


=head2 reset

  await $dev->reset;
  # -> (* no data *)

See documentation of L<virNodeDeviceReset|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceReset>.


=head2 set_autostart

  await $dev->set_autostart( $autostart );
  # -> (* no data *)

See documentation of L<virNodeDeviceSetAutostart|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceSetAutostart>.


=head2 undefine

  await $dev->undefine( $flags = 0 );
  # -> (* no data *)

See documentation of L<virNodeDeviceUndefine|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceUndefine>.


=head2 update

  await $dev->update( $xml_desc, $flags = 0 );
  # -> (* no data *)

See documentation of L<virNodeDeviceUpdate|https://libvirt.org/html/libvirt-libvirt-nodedev.html#virNodeDeviceUpdate>.



=head1 INTERNAL METHODS



=head1 CONSTANTS


   my $value = Sys::Async::Virt::NodeDevice->XML_INACTIVE;

   # - or -

   my $value = $dev->XML_INACTIVE;



=over 8

=item XML_INACTIVE

=item UPDATE_AFFECT_CURRENT

=item UPDATE_AFFECT_LIVE

=item UPDATE_AFFECT_CONFIG

=item EVENT_CREATED

=item EVENT_DELETED

=item EVENT_DEFINED

=item EVENT_UNDEFINED

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2026 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
