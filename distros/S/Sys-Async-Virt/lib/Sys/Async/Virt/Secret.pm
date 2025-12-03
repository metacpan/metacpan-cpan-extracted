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

class Sys::Async::Virt::Secret v0.1.10;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.1.10;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    EVENT_DEFINED   => 0,
    EVENT_UNDEFINED => 1,
};


field $_id :param :reader;
field $_client :param :reader;


async method get_value($flags = 0) {
    return await $_client->_call(
        $remote->PROC_SECRET_GET_VALUE,
        { secret => $_id, flags => $flags // 0 }, unwrap => 'value' );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_SECRET_GET_XML_DESC,
        { secret => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

method set_value($value, $flags = 0) {
    return $_client->_call(
        $remote->PROC_SECRET_SET_VALUE,
        { secret => $_id, value => $value, flags => $flags // 0 }, empty => 1 );
}

method undefine() {
    return $_client->_call(
        $remote->PROC_SECRET_UNDEFINE,
        { secret => $_id }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::Secret - Client side proxy to remote LibVirt secret

=head1 VERSION

v0.1.10

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 get_value

  $value = await $secret->get_value( $flags = 0 );

See documentation of L<virSecretGetValue|https://libvirt.org/html/libvirt-libvirt-secret.html#virSecretGetValue>.


=head2 get_xml_desc

  $xml = await $secret->get_xml_desc( $flags = 0 );

See documentation of L<virSecretGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-secret.html#virSecretGetXMLDesc>.


=head2 set_value

  await $secret->set_value( $value, $flags = 0 );
  # -> (* no data *)

See documentation of L<virSecretSetValue|https://libvirt.org/html/libvirt-libvirt-secret.html#virSecretSetValue>.


=head2 undefine

  await $secret->undefine;
  # -> (* no data *)

See documentation of L<virSecretUndefine|https://libvirt.org/html/libvirt-libvirt-secret.html#virSecretUndefine>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item EVENT_DEFINED

=item EVENT_UNDEFINED

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
