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

class Sys::Async::Virt::NwFilterBinding v0.1.10;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.1.10;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';



field $_id :param :reader;
field $_client :param :reader;


method delete() {
    return $_client->_call(
        $remote->PROC_NWFILTER_BINDING_DELETE,
        { nwfilter => $_id }, empty => 1 );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NWFILTER_BINDING_GET_XML_DESC,
        { nwfilter => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}



1;

__END__

=head1 NAME

Sys::Async::Virt::NwFilterBinding - Client side proxy to remote LibVirt network filter binding

=head1 VERSION

v0.1.10

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 delete

  await $binding->delete;
  # -> (* no data *)

See documentation of L<virNWFilterBindingDelete|https://libvirt.org/html/libvirt-libvirt-nwfilter.html#virNWFilterBindingDelete>.


=head2 get_xml_desc

  $xml = await $binding->get_xml_desc( $flags = 0 );

See documentation of L<virNWFilterBindingGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-nwfilter.html#virNWFilterBindingGetXMLDesc>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8



=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
