####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.10.0
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

class Sys::Async::Virt::Interface v0.2.1;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v11.10.1;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    XML_INACTIVE => 1 << 0,
};


field $_id :param :reader;
field $_client :param :reader;


method create($flags = 0) {
    return $_client->_call(
        $remote->PROC_INTERFACE_CREATE,
        { iface => $_id, flags => $flags // 0 }, empty => 1 );
}

method destroy($flags = 0) {
    return $_client->_call(
        $remote->PROC_INTERFACE_DESTROY,
        { iface => $_id, flags => $flags // 0 }, empty => 1 );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_INTERFACE_GET_XML_DESC,
        { iface => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

async method is_active() {
    return await $_client->_call(
        $remote->PROC_INTERFACE_IS_ACTIVE,
        { iface => $_id }, unwrap => 'active' );
}

method undefine() {
    return $_client->_call(
        $remote->PROC_INTERFACE_UNDEFINE,
        { iface => $_id }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::Interface - Client side proxy to remote LibVirt (network) interface

=head1 VERSION

v0.2.1

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 create

  await $iface->create( $flags = 0 );
  # -> (* no data *)

See documentation of L<virInterfaceCreate|https://libvirt.org/html/libvirt-libvirt-interface.html#virInterfaceCreate>.


=head2 destroy

  await $iface->destroy( $flags = 0 );
  # -> (* no data *)

See documentation of L<virInterfaceDestroy|https://libvirt.org/html/libvirt-libvirt-interface.html#virInterfaceDestroy>.


=head2 get_xml_desc

  $xml = await $iface->get_xml_desc( $flags = 0 );

See documentation of L<virInterfaceGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-interface.html#virInterfaceGetXMLDesc>.


=head2 is_active

  $active = await $iface->is_active;

See documentation of L<virInterfaceIsActive|https://libvirt.org/html/libvirt-libvirt-interface.html#virInterfaceIsActive>.


=head2 undefine

  await $iface->undefine;
  # -> (* no data *)

See documentation of L<virInterfaceUndefine|https://libvirt.org/html/libvirt-libvirt-interface.html#virInterfaceUndefine>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item XML_INACTIVE

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
