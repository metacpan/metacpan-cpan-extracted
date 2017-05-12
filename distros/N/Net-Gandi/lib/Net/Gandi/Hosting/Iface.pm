#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Hosting::Iface;
{
  $Net::Gandi::Hosting::Iface::VERSION = '1.122180';
}

# ABSTRACT: Iface interface

use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use Net::Gandi::Types Client => { -as => 'Client_T' };
use Net::Gandi::Error qw(_validated_params);

use Carp;


has 'id' => ( is => 'rw', isa => 'Int' );

has client => (
    is       => 'rw',
    isa      => Client_T,
    required => 1,
);


sub list {
    my ( $self, $params ) = validated_list(
        \@_,
        opts => { isa => 'HashRef', optional => 1 }
    );

    $params ||= {};
    return $self->client->api_call( "iface.list", $params );
}


sub count {
    my ( $self, $params ) = validated_list(
        \@_,
        opts => { isa => 'HashRef', optional => 1 }
    );

    $params ||= {};
    return $self->client->api_call('iface.count', $params);
}


sub info {
    my ( $self ) = @_;

    carp 'Required parameter id is not defined' if ( ! $self->id );
    return $self->client->api_call( 'iface.info', $self->id );
}


sub create {
    my ( $self, $params ) = validated_list(
        \@_,
        iface_spec => { isa => 'HashRef' }
    );

    _validated_params('iface_create', $params);

    return $self->client->api_call( "iface.create", $params );
}


sub update {
    my ( $self, $params ) = validated_list(
        \@_,
        iface_spec => { isa => 'HashRef' }
    );

    carp 'Required parameter id is not defined' if ( ! $self->id );
    _validated_params('iface_update', $params);

    return $self->client->api_call( "iface.update", $self->id, $params );
}


sub delete {
    my ( $self ) = @_;

    carp 'Required parameter id is not defined' if ( ! $self->id );
    return $self->client->api_call('iface.delete', $self->id);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::Gandi::Hosting::Iface - Iface interface

=head1 VERSION

version 1.122180

=head1 ATTRIBUTES

=head2 id

rw, Int. Id of the iface.

=head1 METHODS

=head2 list

  $iface->list;

List network interfaces.

  input: opts (HashRef) : Filtering options
  output: (HashRef)     : List of List network interfaces

=head2 count

  $iface->count;

Count network interfaces..

  input: opts (HashRef) : Filtering options
  output: (Int)         : number of network interfaces.

=head2 info

Returns informations about the network interface

  input: None
  output: (HashRef) : Network interfaces informations

=head2 create

Create a iface.

  input: iface_spec (HashRef)   : specifications of network interfaces to create
  output: (ArrayRef)         : Operation iface create

=head2 update

Updates network interface attributes.

  input: iface_spec (HashRef) : specifications of network interfaces to update.
  output: (HashRef)  : Iface update operation

=head2 delete

Deletes a network interface.

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

