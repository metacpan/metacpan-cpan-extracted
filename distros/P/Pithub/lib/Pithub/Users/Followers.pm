package Pithub::Users::Followers;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01037';
# ABSTRACT: Github v3 User Followers API

use Moo;
use Carp qw( croak );
extends 'Pithub::Base';


sub follow {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: user' unless $args{user};
    return $self->request(
        method => 'PUT',
        path   => sprintf( '/user/following/%s', delete $args{user} ),
        %args,
    );
}


sub is_following {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: user' unless $args{user};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/user/following/%s', delete $args{user} ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    if ( $args{user} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/users/%s/followers', delete $args{user} ),
            %args,
        );
    }
    return $self->request(
        method => 'GET',
        path   => '/user/followers',
        %args,
    );
}


sub list_following {
    my ( $self, %args ) = @_;
    if ( $args{user} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/users/%s/following', delete $args{user} ),
            %args,
        );
    }
    return $self->request(
        method => 'GET',
        path   => '/user/following',
        %args,
    );
}


sub unfollow {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: user' unless $args{user};
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/user/following/%s', delete $args{user} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Users::Followers - Github v3 User Followers API

=head1 VERSION

version 0.01037

=head1 METHODS

=head2 follow

=over

=item *

Follow a user

    PUT /user/following/:user

Examples:

    my $f = Pithub::Users::Followers->new( token => 'b3c62c6' );
    my $result = $f->follow( user => 'plu' );

=back

=head2 is_following

=over

=item *

Check if the authenticated user is following another given user

    GET /user/following/:user

Examples:

    my $f = Pithub::Users::Followers->new( token => 'b3c62c6' );
    my $result = $f->is_following( user => 'rafl' );

    if ( $result->is_success ) {
        print "plu is following rafl\n";
    }
    elsif ( $result->code == 404 ) {
        print "plu is not following rafl\n";
    }

=back

=head2 list

=over

=item *

List a user's followers:

    GET /users/:user/followers

Examples:

    my $f = Pithub::Users::Followers->new;
    my $result = $f->list( user => 'plu' );

=item *

List the authenticated user's followers:

    GET /user/followers

Examples:

    my $f = Pithub::Users::Followers->new( token => 'b3c62c6' );
    my $result = $f->list;

=back

=head2 list_following

=over

=item *

List who a user is following:

    GET /users/:user/following

Examples:

    my $f = Pithub::Users::Followers->new;
    my $result = $f->list_following( user => 'plu' );

=item *

List who the authenicated user is following:

    GET /user/following

Examples:

    my $f = Pithub::Users::Followers->new( token => 'b3c62c6' );
    my $result = $f->list_following;

=back

=head2 unfollow

=over

=item *

Unfollow a user

    DELETE /user/following/:user

Examples:

    my $f = Pithub::Users::Followers->new;
    my $result = $f->unfollow( user => 'plu' );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
