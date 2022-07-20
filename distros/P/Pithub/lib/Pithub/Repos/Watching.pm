package Pithub::Repos::Watching;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01037';
# ABSTRACT: Github v3 Repo Watching API

use Moo;
use Carp ();
extends 'Pithub::Base';


sub is_watching {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/user/watched/%s/%s', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub list_repos {
    my ( $self, %args ) = @_;
    if ( my $user = delete $args{user} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/users/%s/watched', $user ),
            %args,
        );
    }
    return $self->request(
        method => 'GET',
        path   => '/user/watched',
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/watchers', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub start_watching {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'PUT',
        path   => sprintf( '/user/watched/%s/%s', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub stop_watching {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/user/watched/%s/%s', delete $args{user}, delete $args{repo} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Repos::Watching - Github v3 Repo Watching API

=head1 VERSION

version 0.01037

=head1 METHODS

=head2 is_watching

=over

=item *

Check if you are watching a repo

    GET /user/watched/:user/:repo

Examples:

    my $w = Pithub::Repos::Watching->new;
    my $result = $w->is_watching(
        repo => 'Pithub',
        user => 'plu',
    );

=back

=head2 list_repos

=over

=item *

List repos being watched by a user

    GET /users/:user/watched

Examples:

    my $w = Pithub::Repos::Watching->new;
    my $result = $w->list_repos( user => 'plu' );

=item *

List repos being watched by the authenticated user

    GET /user/watched

Examples:

    my $w = Pithub::Repos::Watching->new;
    my $result = $w->list_repos;

=back

=head2 list

=over

=item *

List watchers

    GET /repos/:user/:repo/watchers

Examples:

    my $w = Pithub::Repos::Watching->new;
    my $result = $w->list(
        user => 'plu',
        repo => 'Pithub',
    );

=back

=head2 start_watching

=over

=item *

Watch a repo

    PUT /user/watched/:user/:repo

Examples:

    my $w = Pithub::Repos::Watching->new;
    my $result = $w->start_watching(
        user => 'plu',
        repo => 'Pithub',
    );

=back

=head2 stop_watching

=over

=item *

Stop watching a repo

    DELETE /user/watched/:user/:repo

Examples:

    my $w = Pithub::Repos::Watching->new;
    my $result = $w->stop_watching(
        user => 'plu',
        repo => 'Pithub',
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
