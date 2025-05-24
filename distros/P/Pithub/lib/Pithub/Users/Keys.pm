package Pithub::Users::Keys;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01042';

# ABSTRACT: Github v3 User Keys API

use Moo;
use Carp qw( croak );
extends 'Pithub::Base';


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    return $self->request(
        method => 'POST',
        path   => '/user/keys',
        %args,
    );
}


sub delete {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: key_id' unless $args{key_id};
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/user/keys/%s', delete $args{key_id} ),
        %args,
    );
}


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: key_id' unless $args{key_id};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/user/keys/%s', delete $args{key_id} ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    return $self->request(
        method => 'GET',
        path   => '/user/keys',
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Users::Keys - Github v3 User Keys API

=head1 VERSION

version 0.01042

=head1 METHODS

=head2 create

=over

=item *

Create a public key

    POST /user/keys

Examples:

    my $k = Pithub::Users::Keys->new( token => 'b3c62c6' );
    my $result = $k->create(
        data => {
            title => 'plu@localhost',
            key   => 'ssh-rsa AAA...',
        }
    );

=back

=head2 delete

=over

=item *

Delete a public key

    DELETE /user/keys/:id

Examples:

    my $k = Pithub::Users::Keys->new( token => 'b3c62c6' );
    my $result = $k->delete( key_id => 123 );

=back

=head2 get

=over

=item *

Get a single public key

    GET /user/keys/:id

Examples:

    my $k = Pithub::Users::Keys->new( token => 'b3c62c6' );
    my $result = $k->get( key_id => 123 );

=back

=head2 list

=over

=item *

List public keys for a user

    GET /user/keys

Examples:

    my $k = Pithub::Users::Keys->new( token => 'b3c62c6' );
    my $result = $k->list;

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
