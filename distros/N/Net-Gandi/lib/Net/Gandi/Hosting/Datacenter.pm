#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Hosting::Datacenter;
{
  $Net::Gandi::Hosting::Datacenter::VERSION = '1.122180';
}

# ABSTRACT: Datacenter interface

use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use Net::Gandi::Types Client => { -as => 'Client_T' };

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
    return $self->client->api_call( 'datacenter.list', $params );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::Gandi::Hosting::Datacenter - Datacenter interface

=head1 VERSION

version 1.122180

=head1 METHODS

=head2 list

  $datacenter->list;

List available datacenters..

  input: opts (HashRef) : Filtering options
  output: (HashRef)     : List of datacenter

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

