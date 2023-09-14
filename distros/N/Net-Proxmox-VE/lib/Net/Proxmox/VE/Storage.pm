#!/bin/false
# vim: softtabstop=2 tabstop=2 shiftwidth=2 ft=perl expandtab smarttab
# PODNAME: Net::Proxmox::VE::Storage
# ABSTRACT: Store object

use strict;
use warnings;

package Net::Proxmox::VE::Storage;
$Net::Proxmox::VE::Storage::VERSION = '0.38';
use parent 'Exporter';

use Carp qw( croak );


our @EXPORT  = qw( storages );

my $base = '/storages';


sub storage {

    my $self = shift or return;

    return $self->get($base);

}


sub get_storage {

    my $self = shift or return;

    my $a = shift or croak 'No storageid for get_storage()';
    croak 'storageid must be a scalar for get_storage()' if ref $a;

    return $self->get( $base, $a );

}


sub create_storage {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for create_storage()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for create_storage()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for create_storage()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $base, \%args )

}


sub delete_storage {

    my $self = shift or return;
    my $a    = shift or croak 'No argument given for delete_storage()';

    return $self->delete( $base, $a );

}


sub update_storage {

    my $self   = shift or return;
    my $storageid = shift or croak 'No storageid provided for update_storage()';
    croak 'storageid must be a scalar for update_storage()' if ref $storageid;
    my @p = @_;

    croak 'No arguments for update_storage()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_storage()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_storage()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, $storageid, \%args );

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Proxmox::VE::Storage - Store object

=head1 VERSION

version 0.38

=head1 SYNOPSIS

  @storage = $obj->storage();
  $storage  = $obj->get_storage('storageid');

  $ok = $obj->create_storage(%args);
  $ok = $obj->create_storage(\%args);

  $ok = $obj->delete_storage('storageid');

  $ok = $obj->update_storage('storageid', %args);
  $ok = $obj->update_storage('storageid', \%args);

=head1 DESCRIPTION

This module implements the 'storages' section of the Proxmox API for L<Net::Proxmox::VE>,
you should use the API via that module. This documentation is for detailed reference.

To be clear, this module isn't useful as a stand alone piece of software.

=head1 NOTE

String formats that are mentioned herein are done so for convenience and
are defined in detail in the Proxmox API documents on the Proxmox project website.

This module doesnt enforce them, it will send whatever garbage you provide
straight to the server API. So garbage-in, garbage-out!

=head1 METHODS

=head2 storages

Gets a list of storages (aka the a Storage Index)

  @storage = $obj->storage();

=head2 get_storage

Gets a single storage's configuration details

  $storage = $obj->get_storage('storageid');

storageid is a string in pve-storageid format

=head2 create_storage

Creates a new storage

  $ok = $obj->create_storage( %args );
  $ok = $obj->create_storage( \%args );

I<%args> may items contain from the following list

=over 4

=item storage

String. The id of the storage you wish to access in pve-storageid format. Required.

=item type

Emum. This is the type of storage, options are dir, nfs, lvm, isci. Required.

=item base

String. A pve-volume-id, see the PVE documentation. Optional.

=item content

String. A pve-storage-content-list. Optional.

=item disable

Boolean. See the PVE documetnation. Optional.

=item export

String. A pve-storage-path. Optional.

=item format

String. A pve-format-path. Optional.

=item maxfiles

Integer. See the PVE documentation. Optional.

=item nodes

String. A pve-node-list. Optional.

=item options

String. A pve-storage-options. Optional.

=item path

String. A pve-storage-path. Optional.

=item portal

String. A pve-storage-portal-dns. Optional.

=item server

String. A pve-storage-server. Optional.

=item shared

Boolean. See the PVE documentation. Optional.

=back

=head2 delete_storage

Deletes a single storage

  $ok = $obj->delete_storage('storage')

storage is a string in pve-storage-id format

=head2 update_storage

Updates (sets) a storage's data

  $ok = $obj->update_storage( 'storage', %args );
  $ok = $obj->update_storage( 'storage', \%args );

storage is a string in pve-storage-id format

I<%args> may items contain from the following list

=over 4

=item content

String. Storage content list. Optional.

=item digest

String. Prevent changes if current configuration file has a different SHA1 digest. This can be used to prevent concurrent modifications. Optional.

=item disable

Boolean. Disables the storage. Optional.

=item format

String. Storage format in pve-storage-format format (see the PVE documentation). Optional.

=item maxfiles

Integer. See PVE documentation. Optional.

=item nodes

String. List of cluster node names. Optional.

=item options

String. Storage options in pve-storage-options format. Optional.

=item shared

Boolean. See PVE documentation. Optional.

=back

=head1 SEE ALSO

L<Net::Proxmox::VE>

=head1 AUTHOR

Brendan Beveridge <brendan@nodeintegration.com.au>, Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Dean Hamstad.

This is free software, licensed under:

  The MIT (X11) License

=cut
