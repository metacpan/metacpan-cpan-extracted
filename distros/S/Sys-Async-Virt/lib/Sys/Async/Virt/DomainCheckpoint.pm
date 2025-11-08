####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.9.0
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

class Sys::Async::Virt::DomainCheckpoint v0.1.8;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.1.8;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    XML_SECURE           => (1 << 0),
    XML_NO_DOMAIN        => (1 << 1),
    XML_SIZE             => (1 << 2),
    LIST_ROOTS           => (1 << 0),
    LIST_DESCENDANTS     => (1 << 0),
    LIST_TOPOLOGICAL     => (1 << 1),
    LIST_LEAVES          => (1 << 2),
    LIST_NO_LEAVES       => (1 << 3),
    DELETE_CHILDREN      => (1 << 0),
    DELETE_METADATA_ONLY => (1 << 1),
    DELETE_CHILDREN_ONLY => (1 << 2),
};


field $_id :param :reader;
field $_client :param :reader;


method delete($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_DELETE,
        { checkpoint => $_id, flags => $flags // 0 }, empty => 1 );
}

async method get_parent($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_GET_PARENT,
        { checkpoint => $_id, flags => $flags // 0 }, unwrap => 'parent' );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_GET_XML_DESC,
        { checkpoint => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

async method list_all_children($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_LIST_ALL_CHILDREN,
        { checkpoint => $_id, need_results => $remote->DOMAIN_SNAPSHOT_LIST_MAX, flags => $flags // 0 }, unwrap => 'checkpoints' );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::DomainCheckpoint - Client side proxy to remote LibVirt domain checkpoint

=head1 VERSION

v0.1.8

=head1 SYNOPSIS

  use Future::AsyncAwait;

  my $domain = await $virt->domain_lookup_by_name( 'domain' );
  my $checkp = await $domain->checkpoint_lookup_by_name( 'checkpoint' );
  my $children = await $checkp->list_all_children();

=head1 DESCRIPTION

Provides access to checkpoints.

=head1 EVENTS

No (LibVirt) events available for domain checkpoints.

=head1 CONSTRUCTOR

=head2 new

Not to be called directly. Various APIs return instances of this type.

=head1 METHODS

=head2 delete

  await $checkpoint->delete( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainCheckpointDelete|https://libvirt.org/html/libvirt-libvirt-domain-checkpoint.html#virDomainCheckpointDelete>.


=head2 get_parent

  $parent = await $checkpoint->get_parent( $flags = 0 );

See documentation of L<virDomainCheckpointGetParent|https://libvirt.org/html/libvirt-libvirt-domain-checkpoint.html#virDomainCheckpointGetParent>.


=head2 get_xml_desc

  $xml = await $checkpoint->get_xml_desc( $flags = 0 );

See documentation of L<virDomainCheckpointGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-domain-checkpoint.html#virDomainCheckpointGetXMLDesc>.


=head2 list_all_children

  $checkpoints = await $checkpoint->list_all_children( $flags = 0 );

See documentation of L<virDomainCheckpointListAllChildren|https://libvirt.org/html/libvirt-libvirt-domain-checkpoint.html#virDomainCheckpointListAllChildren>.



=head1 INTERNAL METHODS



=head1 CONSTANTS

=over 8

=item XML_SECURE

=item XML_NO_DOMAIN

=item XML_SIZE

=item LIST_ROOTS

=item LIST_DESCENDANTS

=item LIST_TOPOLOGICAL

=item LIST_LEAVES

=item LIST_NO_LEAVES

=item DELETE_CHILDREN

=item DELETE_METADATA_ONLY

=item DELETE_CHILDREN_ONLY

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
