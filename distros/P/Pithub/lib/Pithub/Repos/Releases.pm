package Pithub::Repos::Releases;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01035';
# ABSTRACT: Github v3 Repo Releases API

use Moo;
use Carp qw(croak);
use Pithub::Repos::Releases::Assets;
extends 'Pithub::Base';


sub assets {
    return shift->_create_instance('Pithub::Repos::Releases::Assets', @_);
}


sub list {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/releases', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: release_id' unless $args{release_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/releases/%d', delete $args{user}, delete $args{repo}, delete $args{release_id} ),
        %args,
    );
}


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'POST',
        path   => sprintf( '/repos/%s/%s/releases', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: release_id' unless $args{release_id};
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'PATCH',
        path   => sprintf( '/repos/%s/%s/releases/%d', delete $args{user}, delete $args{repo}, delete $args{release_id} ),
        %args,
    );
}


sub delete {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: release_id' unless $args{release_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/repos/%s/%s/releases/%d', delete $args{user}, delete $args{repo}, delete $args{release_id} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Repos::Releases - Github v3 Repo Releases API

=head1 VERSION

version 0.01035

=head1 METHODS

=head2 assets

Provides access to L<Pithub::Repos::Releases::Assets>.

=head2 list

=over

=item *

List releases for a repository.

    GET /repos/:owner/:repo/releases

Examples:

    my $r = Pithub::Repos::Releases->new;
    my $result = $r->get(
        repo => 'Pithub',
        user => 'plu',
    );

=back

=head2 get

=over

=item *

Get a single release.

    GET /repos/:owner/:repo/releases/:id

Examples:

    my $r = Pithub::Repos::Releases->new;
    my $result = $r->get(
        repo       => 'Pithub',
        user       => 'plu',
        release_id => 1,
    );

=back

=head2 create

=over

=item *

Create a release.

    POST /repos/:user/:repo/releases

Examples:

    my $r = Pithub::Repos::Releases->new;
    my $result = $r->create(
        user => 'plu',
        repo => 'Pithub',
        data => {
            tag_name         => 'v1.0.0',
            target_commitish => 'master',
            name             => 'v1.0.0',
            body             => 'Description of the release',
            draft            => 0,
            prerelease       => 0,
        }
    );

=back

=head2 update

=over

=item *

Edit a release.

    PATCH /repos/:user/:repo/releases/:id

Examples:

    my $r = Pithub::Repos::Releases->new;
    my $result = $r->update(
        user       => 'plu',
        repo       => 'Pithub',
        release_id => 1,
        data       => {
            tag_name         => 'v1.0.0',
            target_commitish => 'master',
            name             => 'v1.0.0',
            body             => 'Description of the release',
            draft            => 0,
            prerelease       => 0,
        }
    );

=back

=head2 delete

=over

=item *

Delete a release.

    DELETE /repos/:user/:repo/releases:id

Examples:

    my $r = Pithub::Repos::Releases->new;
    my $result = $r->delete(
        user       => 'plu',
        repo       => 'Pithub',
        release_id => 1,
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2019 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
