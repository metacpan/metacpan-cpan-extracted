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


use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;

package Sys::Async::Virt::Secret v0.0.11;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.11;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    EVENT_DEFINED   => 0,
    EVENT_UNDEFINED => 1,
};


sub new($class, %args) {
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

async sub get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_SECRET_GET_XML_DESC,
        { secret => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

sub set_value($self, $value, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_SECRET_SET_VALUE,
        { secret => $self->{id}, value => $value, flags => $flags // 0 }, empty => 1 );
}

sub undefine($self) {
    return $self->{client}->_call(
        $remote->PROC_SECRET_UNDEFINE,
        { secret => $self->{id} }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::Secret - Client side proxy to remote LibVirt secret

=head1 VERSION

v0.0.11

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

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


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.