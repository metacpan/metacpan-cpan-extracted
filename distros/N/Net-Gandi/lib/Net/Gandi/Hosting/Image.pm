#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Hosting::Image;
{
  $Net::Gandi::Hosting::Image::VERSION = '1.122180';
}

# ABSTRACT: Disk image interface

use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use Net::Gandi::Types Client => { -as => 'Client_T' };

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
    return $self->client->api_call( 'image.list', $params );
}


sub info {
    my ( $self ) = @_;

    carp 'Required parameter id is not defined' if ( ! $self->id );
    return $self->client->api_call( 'image.info', $self->id );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::Gandi::Hosting::Image - Disk image interface

=head1 VERSION

version 1.122180

=head1 ATTRIBUTES

=head2 id

rw, Int. Id of the image.

=head1 METHODS

=head2 list

  $image->list;

List avaible disk image.

  input: opts (HashRef) : Filtering options
  output: (HashRef)     : List of disk image

=head2 info

Perform a image.info

  input: None
  output: (HashRef) : Disk image informations

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

