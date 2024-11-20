####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v10.9.0
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

package Sys::Async::Virt::Interface v0.0.12;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.12;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    XML_INACTIVE => 1 << 0,
};


sub new($class, %args) {
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

sub create($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_INTERFACE_CREATE,
        { iface => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub destroy($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_INTERFACE_DESTROY,
        { iface => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

async sub get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_INTERFACE_GET_XML_DESC,
        { iface => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

async sub is_active($self) {
    return await $self->{client}->_call(
        $remote->PROC_INTERFACE_IS_ACTIVE,
        { iface => $self->{id} }, unwrap => 'active' );
}

sub undefine($self) {
    return $self->{client}->_call(
        $remote->PROC_INTERFACE_UNDEFINE,
        { iface => $self->{id} }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::Interface - Client side proxy to remote LibVirt (network) interface

=head1 VERSION

v0.0.12

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


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.