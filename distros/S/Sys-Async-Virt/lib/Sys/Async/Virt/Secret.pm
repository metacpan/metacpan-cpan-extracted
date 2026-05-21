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

class Sys::Async::Virt::Secret v0.6.3;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v12.3.0;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    EVENT_DEFINED   => 0,
    EVENT_UNDEFINED => 1,
};


field $_rpc_id :param :reader;
field $_client :param :reader;

method uuid() {
    return $_rpc_id->{uuid};
}

method uuid_string() {
    return join( '-', unpack('H8H4H4H4H12', $_rpc_id->{uuid}) );
}

method usage_type() {
    return $_rpc_id->{usageType};
}

method usage_id() {
    return $_rpc_id->{usageID};
}

async method get_value($flags = 0) {
    return await $_client->_call(
        $remote->PROC_SECRET_GET_VALUE,
        { secret => $_rpc_id, flags => $flags // 0 }, unwrap => 'value' );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_SECRET_GET_XML_DESC,
        { secret => $_rpc_id, flags => $flags // 0 }, unwrap => 'xml' );
}

method set_value($value, $flags = 0) {
    return $_client->_call(
        $remote->PROC_SECRET_SET_VALUE,
        { secret => $_rpc_id, value => $value, flags => $flags // 0 }, empty => 1 );
}

method undefine() {
    return $_client->_call(
        $remote->PROC_SECRET_UNDEFINE,
        { secret => $_rpc_id }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::Secret - Client side proxy to remote LibVirt secret

=head1 VERSION

v0.6.3

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 uuid

  $uuid = $secret->uuid;

Returns a 16-byte string containing the (binary) UUID.

=head2 uuid_string

  $str = $secret->uuid_string;

Returns the string representation of the UUID (C<xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx>).

=head2 usage_type

  my $usage_type = $secret->usage_type;

Returns the usage type of the secret.

=head2 usage_id

  my $usage_id = $secret->usage_id;

Returns the identifier of he object with which the secret is to be used.

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


   my $value = Sys::Async::Virt::Secret->EVENT_DEFINED;

   # - or -

   my $value = $secret->EVENT_DEFINED;



=over 8

=item EVENT_DEFINED

=item EVENT_UNDEFINED

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2026 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
