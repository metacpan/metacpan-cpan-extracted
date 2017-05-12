#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Domain;
{
  $Net::Gandi::Domain::VERSION = '1.122180';
}

# ABSTRACT: Domain interface

use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use Net::Gandi::Types Client => { -as => 'Client_T' };

use Carp;


has domain => ( is => 'rw', isa => 'Str' );

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
    return $self->client->api_call( "domain.list", $params );
}


sub count {
    my ( $self, $params ) = validated_list(
        \@_,
        opts => { isa => 'HashRef', optional => 1 }
    );

    $params ||= {};
    return $self->client->api_call('domain.count', $params);
}


sub info {
    my ( $self ) = @_;

    carp 'Required parameter domain attribute is not defined'
        if ( ! $self->domain );
    return $self->client->api_call( 'domain.info', $self->domain );
}

1;

__END__
=pod

=head1 NAME

Net::Gandi::Domain - Domain interface

=head1 VERSION

version 1.122180

=head1 ATTRIBUTES

=head2 apikey

rw, Str. The domain name.

=head1 METHODS

=head2 list

  $domain->list;

List domains associated to the contact represented by apikey.

  input: opts (HashRef) : Filtering options
  output: (HashRef)     : List of domains

=head2 count

  $domain->count;

Count domains associated to the contact represented by apikey.

  input: opts (HashRef) : Filtering options
  output: (Int)         : count of domain

=head2 info

  $domain->info

Get domain information.

  input: None
  output: (HashRef) : Domain information

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

