#!/bin/false
# vim: softtabstop=2 tabstop=2 shiftwidth=2 ft=perl expandtab smarttab
# PODNAME: Net::Proxmox::VE::Pools
# ABSTRACT: Presents a pool object

use strict;
use warnings;

package Net::Proxmox::VE::Pools;
$Net::Proxmox::VE::Pools::VERSION = '0.37';
use parent 'Exporter';

use Carp qw( croak );


our @EXPORT  = qw( pools get_pool create_pool delete_pool update_pool );

my $base = '/pools';


sub pools {

    my $self = shift or return;

    return $self->get($base);

}


sub get_pool {

    my $self = shift or return;

    my $a = shift or croak 'No poolid for get_pool()';
    croak 'poolid must be a scalar for get_pool()' if ref $a;

    return $self->get( $base, $a );

}


sub create_pool {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for create_pool()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for create_pool()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for create_pool()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $base, \%args )

}


sub delete_pool {

    my $self = shift or return;
    my $a    = shift or croak 'No argument given for delete_pool()';

    return $self->delete( $base, $a );

}


sub update_pool {

    my $self   = shift or return;
    my $poolid = shift or croak 'No poolid provided for update_pool()';
    croak 'poolid must be a scalar for update_pool()' if ref $poolid;
    my @p = @_;

    croak 'No arguments for update_pool()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_pool()'
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_pool()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, $poolid, \%args )

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Proxmox::VE::Pools - Presents a pool object

=head1 VERSION

version 0.37

=head1 SYNOPSIS

  @pools = $obj->pools();
  $pool  = $obj->get_pool('poolid');

  $ok = $obj->create_pool(%args);
  $ok = $obj->create_pool(\%args);

  $ok = $obj->delete_pool('poolid');

  $ok = $obj->update_pool('poolid', %args);
  $ok = $obj->update_pool('poolid', \%args);

=head1 DESCRIPTION

This module implements the 'pools' section of the Proxmox API for L<Net::Proxmox::VE>,
you should use the API via that module. This documentation is for detailed reference.

To be clear, this module isn't useful as a stand alone piece of software.

=head1 NOTE

String formats that are mentioned herein are done so for convenience and
are defined in detail in the Proxmox API documents on the Proxmox project website.

This module doesnt enforce them, it will send whatever garbage you provide
straight to the server API. So garbage-in, garbage-out!

=head1 METHODS

=head2 pools

Gets a list of pools (aka the a Pool Index)

  @pools = $obj->pools();

=head2 get_pool

Gets a single pool's configuration details

  $pool = $obj->get_pool('poolid');

poolid is a string in pve-poolid format

=head2 create_pool

Creates a new pool

  $ok = $obj->create_pool( %args );
  $ok = $obj->create_pool( \%args );

I<%args> may items contain from the following list

=over 4

=item poolid

String. The id of the pool you wish to access, in pve-poolid format. This is required.

=item comment

String. This is a comment associated with the new pool, this is optional

=back

=head2 delete_pool

Deletes a single pool

  $ok = $obj->delete_pool('poolid')

poolid is a string in pve-poolid format

=head2 update_pool

Updates (sets) a pool's data

  $ok = $obj->update_pool( 'poolid', %args );
  $ok = $obj->update_pool( 'poolid', \%args );

poolid is a string in pve-poolid format

I<%args> may items contain from the following list

=over 4

=item comment

String. This is a comment associated with the new pool, this is optional

=item delete

Boolean. Removes the vms/storage rather than adding it.

=item storage

String. List of storage ids (in pve-storage-id-list format)

=item vms

String. List of virtual machines in pve-vmid-list format.

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
