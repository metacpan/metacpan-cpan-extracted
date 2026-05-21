####################################################################
#
#     This file was generated using XDR::Parse version v1.0.1
#                   and LibVirt version v12.3.0
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

class Sys::Async::Virt::NwFilterBinding v0.6.3;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v12.3.0;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';



field $_rpc_id :param :reader;
field $_client :param :reader;

method name() {
    return $_rpc_id->{name};
}

method port() {
    return $_client->_network_port_instance( $_rpc_id->{portdev} );
}

method delete() {
    return $_client->_call(
        $remote->PROC_NWFILTER_BINDING_DELETE,
        { nwfilter => $_rpc_id }, empty => 1 );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NWFILTER_BINDING_GET_XML_DESC,
        { nwfilter => $_rpc_id, flags => $flags // 0 }, unwrap => 'xml' );
}



1;

__END__

=head1 NAME

Sys::Async::Virt::NwFilterBinding - Client side proxy to remote LibVirt network filter binding

=head1 VERSION

v0.6.3

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 name

  $name = $binding->name;

Returns the name of the filter binding.

=head2 port

  $port = $binding->port;

Returns the L<Sys::Async::Virt::NetworkPort> instance this binding associates with.

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


  Copyright (C) 2024-2026 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
