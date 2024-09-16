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


use v5.20;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;

package Sys::Async::Virt::Network v0.0.1;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.1;
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


sub new {
    my ($class, %args) = @_;
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

sub create($self) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_CREATE,
        { net => $self->{id},  } );
}

sub destroy($self) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_DESTROY,
        { net => $self->{id},  } );
}

sub get_autostart($self) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_GET_AUTOSTART,
        { net => $self->{id},  } );
}

sub get_bridge_name($self) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_GET_BRIDGE_NAME,
        { net => $self->{id},  } );
}

sub get_metadata($self, $type, $uri, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_GET_METADATA,
        { network => $self->{id}, type => $type, uri => $uri, flags => $flags // 0 } );
}

sub get_xml_desc($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_GET_XML_DESC,
        { net => $self->{id}, flags => $flags // 0 } );
}

sub is_active($self) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_IS_ACTIVE,
        { net => $self->{id},  } );
}

sub is_persistent($self) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_IS_PERSISTENT,
        { net => $self->{id},  } );
}

sub list_all_ports($self, $need_results, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_LIST_ALL_PORTS,
        { network => $self->{id}, need_results => $need_results, flags => $flags // 0 } );
}

sub port_create_xml($self, $xml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_PORT_CREATE_XML,
        { network => $self->{id}, xml => $xml, flags => $flags // 0 } );
}

sub port_lookup_by_uuid($self, $uuid) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_PORT_LOOKUP_BY_UUID,
        { network => $self->{id}, uuid => $uuid } );
}

sub set_autostart($self, $autostart) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_SET_AUTOSTART,
        { net => $self->{id}, autostart => $autostart } );
}

sub set_metadata($self, $type, $metadata, $key, $uri, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_SET_METADATA,
        { network => $self->{id}, type => $type, metadata => $metadata, key => $key, uri => $uri, flags => $flags // 0 } );
}

sub undefine($self) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_UNDEFINE,
        { net => $self->{id},  } );
}

sub update($self, $command, $section, $parentIndex, $xml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_NETWORK_UPDATE,
        { net => $self->{id}, command => $command, section => $section, parentIndex => $parentIndex, xml => $xml, flags => $flags // 0 } );
}



1;


__END__


=head1 NAME

Sys::Async::Virt::Network - Client side proxy to remote LibVirt network

=head1 VERSION

v0.0.1

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

  $ports = await $net->list_all_ports( $need_results, $flags = 0 );

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


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.