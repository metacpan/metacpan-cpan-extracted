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

package Sys::Async::Virt::NwFilter v0.0.1;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.1;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';



sub new {
    my ($class, %args) = @_;
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

sub get_xml_desc($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_NWFILTER_GET_XML_DESC,
        { nwfilter => $self->{id}, flags => $flags // 0 } );
}

sub undefine($self) {
    return $self->{client}->_call(
        $remote->PROC_NWFILTER_UNDEFINE,
        { nwfilter => $self->{id},  } );
}



1;

__END__

=head1 NAME

Sys::Async::Virt::NwFilter - Client side proxy to remote LibVirt network filter

=head1 VERSION

v0.0.1

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EVENTS

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 get_xml_desc

  $xml = await $filter->get_xml_desc( $flags = 0 );

See documentation of L<virNWFilterGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-nwfilter.html#virNWFilterGetXMLDesc>.


=head2 undefine

  await $filter->undefine;
  # -> (* no data *)

See documentation of L<virNWFilterUndefine|https://libvirt.org/html/libvirt-libvirt-nwfilter.html#virNWFilterUndefine>.



=head1 CONSTANTS

=over 8



=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.