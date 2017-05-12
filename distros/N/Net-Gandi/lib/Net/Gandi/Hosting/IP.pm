#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Hosting::IP;
{
  $Net::Gandi::Hosting::IP::VERSION = '1.122180';
}

# ABSTRACT: Ip interface

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
    return $self->client->api_call( 'ip.list', $params );
}


sub count {
    my ( $self, $params ) = validated_list(
        \@_,
        opts => { isa => 'HashRef', optional => 1 }
    );

    $params ||= {};
    return $self->client->api_call('ip.count', $params);
}


sub info {
    my ( $self ) = @_;

    carp 'Required parameter id is not defined' if ( ! $self->id );
    return $self->client->api_call( 'ip.info', $self->id );
}


sub update {
    my ( $self, $params ) = validated_list(
        \@_,
        ip_spec => { isa => 'HashRef' }
    );

    carp 'Required parameter id is not defined' if ( ! $self->id );
    _validated_params('ip_update', $params);

    $params ||= {};
    return $self->client->api_call('ip.update', $self->id, $params);
}

#sub attach {
#    my ( $self, $iface_id ) = @_;
#
#    return $self->client->api_call('iface.attach', $iface_id, $self->id);
#}


#sub detach {
#    my ( $self, $iface_id ) = @_;
#
#    return $self->client->api_call('iface.detach', $iface_id, $self->id);
#}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::Gandi::Hosting::IP - Ip interface

=head1 VERSION

version 1.122180

=head1 ATTRIBUTES

=head2 id

rw, Int. Id of the ip.

=head1 METHODS

=head2 list

  $ip->list;

List ip addresses.

  input: opts (HashRef) : Filtering options
  output: (HashRef)     : List of ip

=head2 count

  $ip->count;

Count ip adresses.

  input: opts (HashRef) : Filtering options
  output: (Int)         : number of ip

=head2 info

Return a mapping of the IP attributes.

  input: None
  output: (HashRef) : Vm informations

=head2 update

Updates a IP’s attributes

  input: ip_spec (HashRef) : specifications of the ip address to update
  output: (HashRef)        : Operation ip update

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

