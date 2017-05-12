package Net::Iugu::CRUD;
$Net::Iugu::CRUD::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::Request';

sub create {
    my ( $self, $data ) = @_;

    my $uri = $self->endpoint;

    return $self->request( POST => $uri, $data );
}

sub read {
    my ( $self, $object_id ) = @_;

    my $uri = $self->endpoint . '/' . $object_id;

    return $self->request( GET => $uri );
}

sub update {
    my ( $self, $object_id, $data ) = @_;

    my $uri = $self->endpoint . '/' . $object_id;

    return $self->request( PUT => $uri, $data );
}

sub delete {
    my ( $self, $object_id ) = @_;

    my $uri = $self->endpoint . '/' . $object_id;

    return $self->request( DELETE => $uri );
}

sub list {
    my ( $self, $params ) = @_;

    return $self->request( GET => $self->endpoint, $params );
}

1;

# ABSTRACT: Net::Iugu::CRUD - Methods for basic CRUD

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu::CRUD - Net::Iugu::CRUD - Methods for basic CRUD

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the basic CRUD operations for some endpoints of the Iugu API.
It is used as base class for other modules and shouldn't be instantiated
directly.

    package Net::Iugu::Endpoint;

    use Moo;
    extends 'Net::Iugu::CRUD';

    ...

    pachage main;

    use Net::Iugu::Endpoint;

    my $endpoint = Net::Iugu::Endpoint->new(
        token => 'my_api_token'
    );

    my $res;
    $res = $endpoint->create( $data );
    $res = $endpoint->read( $object_id );
    $res = $endpoint->update( $object_id, $data );
    $res = $endpoint->delete( $object_id );
    $res = $endpoint->list( $params );

=head1 METHODS

=head2 create( $data )

Creates a new object.

=head2 read( $object_id )

Returns data of an object.

=head2 update( $object_id, $data )

Updates an object.

=head2 delete( $object_id )

Removes an object.

=head2 list( $params )

Returns a list o objects.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
