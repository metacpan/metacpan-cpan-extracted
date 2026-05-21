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

class Sys::Async::Virt::NwFilter v0.6.3;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v12.3.0;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';



field $_rpc_id :param :reader;
field $_client :param :reader;

method name() {
    return $_rpc_id->{name};
}

method uuid() {
    return $_rpc_id->{uuid};
}

method uuid_string() {
    return join( '-', unpack('H8H4H4H4H12', $_rpc_id->{uuid}) );
}


async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_NWFILTER_GET_XML_DESC,
        { nwfilter => $_rpc_id, flags => $flags // 0 }, unwrap => 'xml' );
}

method undefine() {
    return $_client->_call(
        $remote->PROC_NWFILTER_UNDEFINE,
        { nwfilter => $_rpc_id }, empty => 1 );
}



1;

__END__

=head1 NAME

Sys::Async::Virt::NwFilter - Client side proxy to remote LibVirt network filter

=head1 VERSION

v0.6.3

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 name

  $name = $filter->name;

Returns the name of the network filter.

=head2 uuid

  $uuid = $filter->uuid;

Returns a 16-byte string containing the (binary) UUID.

=head2 uuid_string

  $str = $filter->uuid_string;

Returns the string representation of the UUID (C<xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx>).

=head2 get_xml_desc

  $xml = await $filter->get_xml_desc( $flags = 0 );

See documentation of L<virNWFilterGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-nwfilter.html#virNWFilterGetXMLDesc>.


=head2 undefine

  await $filter->undefine;
  # -> (* no data *)

See documentation of L<virNWFilterUndefine|https://libvirt.org/html/libvirt-libvirt-nwfilter.html#virNWFilterUndefine>.



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
