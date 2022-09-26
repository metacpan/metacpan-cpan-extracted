package Pithub::Users;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01040';
# ABSTRACT: Github v3 Users API

use Moo;
use Carp qw( croak );
use Pithub::Users::Emails;
use Pithub::Users::Followers;
use Pithub::Users::Keys;
extends 'Pithub::Base';


sub emails {
    return shift->_create_instance('Pithub::Users::Emails', @_);
}


sub followers {
    return shift->_create_instance('Pithub::Users::Followers', @_);
}


sub get {
    my ( $self, %args ) = @_;
    if ( $args{user} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/users/%s', delete $args{user} ),
            %args,
        );
    }
    return $self->request(
        method => 'GET',
        path   => '/user',
        %args,
    );
}


sub keys {
    return shift->_create_instance('Pithub::Users::Keys', @_);
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    return $self->request(
        method => 'PATCH',
        path   => '/user',
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Users - Github v3 Users API

=head1 VERSION

version 0.01040

=head1 METHODS

=head2 emails

Provides access to L<Pithub::Users::Emails>.

=head2 followers

Provides access to L<Pithub::Users::Followers>.

=head2 get

=over

=item *

Get a single user

    GET /users/:user

Examples:

    my $u = Pithub::Users->new;
    my $result = $u->get( user => 'plu');

=item *

Get the authenticated user

    GET /user

Examples:

    my $u = Pithub::Users->new( token => 'b3c62c6' );
    my $result = $u->get;

=back

=head2 keys

Provides access to L<Pithub::Users::Keys>.

=head2 update

=over

=item *

Update the authenticated user

    PATCH /user

Examples:

    my $u = Pithub::Users->new( token => 'b3c62c6' );
    my $result = $u->update( data => { email => 'plu@cpan.org' } );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
