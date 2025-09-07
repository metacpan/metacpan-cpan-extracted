####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.7.0
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

class Sys::Async::Virt::Network v0.1.5;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.1.5;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    XML_INACTIVE              => (1 << 0),
    UPDATE_COMMAND_NONE       => 0,
    UPDATE_COMMAND_MODIFY     => 1,
    UPDATE_COMMAND_DELETE     => 2,
    UPDATE_COMMAND_ADD_LAST   => 3,
    UPDATE_COMMAND_ADD_FIRST  => 4,
    SECTION_NONE              => 0,
    SECTION_BRIDGE            => 1,
    SECTION_DOMAIN            => 2,
    SECTION_IP                => 3,
    SECTION_IP_DHCP_HOST      => 4,
    SECTION_IP_DHCP_RANGE     => 5,
    SECTION_FORWARD           => 6,
    SECTION_FORWARD_INTERFACE => 7,
    SECTION_FORWARD_PF        => 8,
    SECTION_PORTGROUP         => 9,
    SECTION_DNS_HOST          => 10,
    SECTION_DNS_TXT           => 11,
    SECTION_DNS_SRV           => 12,
    UPDATE_AFFECT_CURRENT     => 0,
    UPDATE_AFFECT_LIVE        => 1 << 0,
    UPDATE_AFFECT_CONFIG      => 1 << 1,
    EVENT_DEFINED             => 0,
    EVENT_UNDEFINED           => 1,
    EVENT_STARTED             => 2,
    EVENT_STOPPED             => 3,
    PORT_CREATE_RECLAIM       => (1 << 0),
    PORT_CREATE_VALIDATE      => (1 << 1),
    METADATA_DESCRIPTION      => 0,
    METADATA_TITLE            => 1,
    METADATA_ELEMENT          => 2,
};


field $_id :param :reader;
field $_client :param :reader;


method create() {
    return $_client->_call(
        $remote->PROC_NETWORK_CREATE,
        { net => $_id }, empty => 1 );
}

method destroy() {
    return $_client->_call(
        $remote->PROC_NETWORK_DESTROY,
        { net => $_id }, empty => 1 );
}

async method get_autostart() {
    return await $_client->_call(
        $remote->PROC_NETWORK_GET_AUTOSTART,
        { net => $_id }, unwrap => 'autostart' );
}

async method get_bridge_name() {
    return await $_client->_call(
        $remote->PROC_NETWORK_GET_BRIDGE_NAME,
        { net => $_id }, unwrap => 'name' );
}

async method get_dhcp_leases($mac, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_NETWORK_GET_DHCP_LEASES,
        { net => $_id, mac => $mac, need_results => $remote->NETWORK_DHCP_LEASES_MAX, flags => $flags // 0 }, unwrap => 'leases' );
}

async method get_metadata($type, $uri, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_NETWORK_GET_METADATA,
        { network => $_id, type => $type, uri => $uri, flags => $flags // 0 }, unwrap => 'metadata' );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NETWORK_GET_XML_DESC,
        { net => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

async method is_active() {
    return await $_client->_call(
        $remote->PROC_NETWORK_IS_ACTIVE,
        { net => $_id }, unwrap => 'active' );
}

async method is_persistent() {
    return await $_client->_call(
        $remote->PROC_NETWORK_IS_PERSISTENT,
        { net => $_id }, unwrap => 'persistent' );
}

async method list_all_ports($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NETWORK_LIST_ALL_PORTS,
        { network => $_id, need_results => $remote->NETWORK_PORT_LIST_MAX, flags => $flags // 0 }, unwrap => 'ports' );
}

async method port_create_xml($xml, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_NETWORK_PORT_CREATE_XML,
        { network => $_id, xml => $xml, flags => $flags // 0 }, unwrap => 'port' );
}

async method port_lookup_by_uuid($uuid) {
    return await $_client->_call(
        $remote->PROC_NETWORK_PORT_LOOKUP_BY_UUID,
        { network => $_id, uuid => $uuid }, unwrap => 'port' );
}

method set_autostart($autostart) {
    return $_client->_call(
        $remote->PROC_NETWORK_SET_AUTOSTART,
        { net => $_id, autostart => $autostart }, empty => 1 );
}

method set_metadata($type, $metadata, $key, $uri, $flags = 0) {
    return $_client->_call(
        $remote->PROC_NETWORK_SET_METADATA,
        { network => $_id, type => $type, metadata => $metadata, key => $key, uri => $uri, flags => $flags // 0 }, empty => 1 );
}

method undefine() {
    return $_client->_call(
        $remote->PROC_NETWORK_UNDEFINE,
        { net => $_id }, empty => 1 );
}

method update($command, $section, $parentIndex, $xml, $flags = 0) {
    return $_client->_call(
        $remote->PROC_NETWORK_UPDATE,
        { net => $_id, command => $command, section => $section, parentIndex => $parentIndex, xml => $xml, flags => $flags // 0 }, empty => 1 );
}



1;


__END__


=head1 NAME

Sys::Async::Virt::Network - Client side proxy to remote LibVirt network

=head1 VERSION

v0.1.5

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 create

  await $net->create;
  # -> (* no data *)

See documentation of L<virNetworkCreate|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkCreate>.


=head2 destroy

  await $net->destroy;
  # -> (* no data *)

See documentation of L<virNetworkDestroy|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkDestroy>.


=head2 get_autostart

  $autostart = await $net->get_autostart;

See documentation of L<virNetworkGetAutostart|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkGetAutostart>.


=head2 get_bridge_name

  $name = await $net->get_bridge_name;

See documentation of L<virNetworkGetBridgeName|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkGetBridgeName>.


=head2 get_dhcp_leases

  $leases = await $net->get_dhcp_leases( $mac, $flags = 0 );

See documentation of L<virNetworkGetDHCPLeases|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkGetDHCPLeases>.


=head2 get_metadata

  $metadata = await $net->get_metadata( $type, $uri, $flags = 0 );

See documentation of L<virNetworkGetMetadata|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkGetMetadata>.


=head2 get_xml_desc

  $xml = await $net->get_xml_desc( $flags = 0 );

See documentation of L<virNetworkGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkGetXMLDesc>.


=head2 is_active

  $active = await $net->is_active;

See documentation of L<virNetworkIsActive|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkIsActive>.


=head2 is_persistent

  $persistent = await $net->is_persistent;

See documentation of L<virNetworkIsPersistent|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkIsPersistent>.


=head2 list_all_ports

  $ports = await $net->list_all_ports( $flags = 0 );

See documentation of L<virNetworkListAllPorts|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkListAllPorts>.


=head2 port_create_xml

  $port = await $net->port_create_xml( $xml, $flags = 0 );

See documentation of L<virNetworkPortCreateXML|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkPortCreateXML>.


=head2 port_lookup_by_uuid

  $port = await $net->port_lookup_by_uuid( $uuid );

See documentation of L<virNetworkPortLookupByUUID|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkPortLookupByUUID>.


=head2 set_autostart

  await $net->set_autostart( $autostart );
  # -> (* no data *)

See documentation of L<virNetworkSetAutostart|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkSetAutostart>.


=head2 set_metadata

  await $net->set_metadata( $type, $metadata, $key, $uri, $flags = 0 );
  # -> (* no data *)

See documentation of L<virNetworkSetMetadata|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkSetMetadata>.


=head2 undefine

  await $net->undefine;
  # -> (* no data *)

See documentation of L<virNetworkUndefine|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkUndefine>.


=head2 update

  await $net->update( $command, $section, $parentIndex, $xml, $flags = 0 );
  # -> (* no data *)

See documentation of L<virNetworkUpdate|https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkUpdate>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item XML_INACTIVE

=item UPDATE_COMMAND_NONE

=item UPDATE_COMMAND_MODIFY

=item UPDATE_COMMAND_DELETE

=item UPDATE_COMMAND_ADD_LAST

=item UPDATE_COMMAND_ADD_FIRST

=item SECTION_NONE

=item SECTION_BRIDGE

=item SECTION_DOMAIN

=item SECTION_IP

=item SECTION_IP_DHCP_HOST

=item SECTION_IP_DHCP_RANGE

=item SECTION_FORWARD

=item SECTION_FORWARD_INTERFACE

=item SECTION_FORWARD_PF

=item SECTION_PORTGROUP

=item SECTION_DNS_HOST

=item SECTION_DNS_TXT

=item SECTION_DNS_SRV

=item UPDATE_AFFECT_CURRENT

=item UPDATE_AFFECT_LIVE

=item UPDATE_AFFECT_CONFIG

=item EVENT_DEFINED

=item EVENT_UNDEFINED

=item EVENT_STARTED

=item EVENT_STOPPED

=item PORT_CREATE_RECLAIM

=item PORT_CREATE_VALIDATE

=item METADATA_DESCRIPTION

=item METADATA_TITLE

=item METADATA_ELEMENT

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
