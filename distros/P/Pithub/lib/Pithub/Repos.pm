package Pithub::Repos;
our $AUTHORITY = 'cpan:PLU';

# ABSTRACT: Github v3 Repos API

use Moo;

our $VERSION = '0.01041';

use Carp                         qw( croak );
use Pithub::Issues               ();
use Pithub::Markdown             ();
use Pithub::PullRequests         ();
use Pithub::Repos::Actions       ();
use Pithub::Repos::Collaborators ();
use Pithub::Repos::Commits       ();
use Pithub::Repos::Contents      ();
use Pithub::Repos::Downloads     ();
use Pithub::Repos::Forks         ();
use Pithub::Repos::Hooks         ();
use Pithub::Repos::Keys          ();
use Pithub::Repos::Releases      ();
use Pithub::Repos::Starring      ();
use Pithub::Repos::Stats         ();
use Pithub::Repos::Statuses      ();
use Pithub::Repos::Watching      ();

extends 'Pithub::Base';


sub actions {
    return shift->_create_instance( Pithub::Repos::Actions::, @_ );
}


sub branch {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: branch (string)'
        unless defined $args{branch};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/branches/%s', delete $args{user},
            delete $args{repo},
            delete $args{branch},
        ),
        %args,
    );
}


sub branches {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/branches', delete $args{user}, delete $args{repo}
        ),
        %args,
    );
}


sub rename_branch {
    my ( $self, %args ) = @_;
    croak 'Missing parameters: branch' unless $args{branch};
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'POST',
        path   => sprintf(
            '/repos/%s/%s/branches/%s/rename', delete $args{user},
            delete $args{repo},                delete $args{branch}
        ),
        %args,
    );
}


sub merge_branch {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'POST',
        path   => sprintf(
            '/repos/%s/%s/merges', delete $args{user}, delete $args{repo}
        ),
        %args,
    );
}


sub collaborators {
    return shift->_create_instance( Pithub::Repos::Collaborators::, @_ );
}


sub commits {
    return shift->_create_instance( Pithub::Repos::Commits::, @_ );
}


sub contents {
    return shift->_create_instance( Pithub::Repos::Contents::, @_ );
}


sub contributors {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/contributors', delete $args{user},
            delete $args{repo}
        ),
        %args,
    );
}


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    if ( my $org = delete $args{org} ) {
        return $self->request(
            method => 'POST',
            path   => sprintf( '/orgs/%s/repos', $org ),
            %args,
        );
    }
    else {
        return $self->request(
            method => 'POST',
            path   => '/user/repos',
            %args,
        );
    }
}


sub delete {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'DELETE',
        path   =>
            sprintf( '/repos/%s/%s', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub downloads {
    return shift->_create_instance( Pithub::Repos::Downloads::, @_ );
}


sub forks {
    return shift->_create_instance( Pithub::Repos::Forks::, @_ );
}


sub get {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   =>
            sprintf( '/repos/%s/%s', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub hooks {
    return shift->_create_instance( Pithub::Repos::Hooks::, @_ );
}


sub issues {
    return shift->_create_instance( Pithub::Issues::, @_ );
}


sub keys {
    return shift->_create_instance( Pithub::Repos::Keys::, @_ );
}


sub languages {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/languages', delete $args{user}, delete $args{repo}
        ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    if ( my $user = delete $args{user} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/users/%s/repos', $user ),
            %args,
        );
    }
    elsif ( my $org = delete $args{org} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/orgs/%s/repos', $org ),
            %args
        );
    }
    else {
        return $self->request(
            method => 'GET',
            path   => '/user/repos',
            %args,
        );
    }
}


sub markdown {
    my $self = shift;
    return $self->_create_instance(
        Pithub::Markdown::,
        mode    => 'gfm',
        context => sprintf( '%s/%s', $self->user, $self->repo ),
        @_
    );
}


sub pull_requests {
    return shift->_create_instance( Pithub::PullRequests::, @_ );
}


sub releases {
    return shift->_create_instance( Pithub::Repos::Releases::, @_ );
}


sub starring {
    return shift->_create_instance( Pithub::Repos::Starring::, @_ );
}


sub stats {
    return shift->_create_instance( Pithub::Repos::Stats::, @_ );
}


sub statuses {
    return shift->_create_instance( Pithub::Repos::Statuses::, @_ );
}


sub tags {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/tags', delete $args{user}, delete $args{repo}
        ),
        %args,
    );
}


sub teams {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/teams', delete $args{user}, delete $args{repo}
        ),
        %args,
    );
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'PATCH',
        path   =>
            sprintf( '/repos/%s/%s', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub watching {
    return shift->_create_instance( Pithub::Repos::Watching::, @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Repos - Github v3 Repos API

=head1 VERSION

version 0.01041

=head1 METHODS

=head2 actions

Provides access to L<Pithub::Repos::Actions>.

=head2 branch

Get information about a single branch.

    GET /repos/:owner/:repo/branches/:branch

Example:

    my $result = Pithub->new->branch(
        user => 'plu',
        repo => 'Pithub',
        branch => "master"
    );

See also L<branches> to get a list of all branches.

=head2 branches

=over

=item *

List Branches

    GET /repos/:user/:repo/branches

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->branches( user => 'plu', repo => 'Pithub' );

See also L<branch> to get information about a single branch.

=back

=head2 rename_branch

=over

=item *

Rename a branch

    POST /repos/:user/:repo/branches/:branch/rename

Examples:

    my $b = Pithub::Repos->new;
    my $result = $b->rename_branch(
        user => 'plu',
        repo => 'Pithub',
        branch  => 'travis',
        data => { new_name => 'travis-ci' }
    );

=back

=head2 merge_branch

=over

=item *

Merge a branch

    POST /repos/:user/:repo/merges

Examples:

    my $b = Pithub::Repos->new;
    my $result = $b->rename_branch(
        user => 'plu',
        repo => 'Pithub',
        data => { base => 'master', head => 'travis', message => 'My commit message' }
    );

=back

=head2 collaborators

Provides access to L<Pithub::Repos::Collaborators>.

=head2 commits

Provides access to L<Pithub::Repos::Commits>.

=head2 contents

Provides access to L<Pithub::Repos::Contents>.

=head2 contributors

=over

=item *

List contributors

    GET /repos/:user/:repo/contributors

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->contributors( user => 'plu', repo => 'Pithub' );

=back

=head2 create

=over

=item *

Create a new repository for the authenticated user.

    POST /user/repos

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->create( data => { name => 'some-repo' } );

=item *

Create a new repository in this organization. The authenticated user
must be a member of this organization.

    POST /orgs/:org/repos

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->create(
        org  => 'CPAN-API',
        data => { name => 'some-repo' }
    );

=back

=head2 delete

Delete a repository.

    DELETE /repos/:owner/:repo

=head2 downloads

Provides access to L<Pithub::Repos::Downloads>.

=head2 forks

Provides access to L<Pithub::Repos::Forks>.

=head2 get

=over

=item *

Get a repo

    GET /repos/:user/:repo

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->get( user => 'plu', repo => 'Pithub' );

=back

=head2 hooks

Provides access to L<Pithub::Repos::Hooks>.

=head2 issues

Provides access to L<Pithub::Issues> for this repo.

=head2 keys

Provides access to L<Pithub::Repos::Keys>.

=head2 languages

=over

=item *

List languages

    GET /repos/:user/:repo/languages

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->languages( user => 'plu', repo => 'Pithub' );

=back

=head2 list

=over

=item *

List repositories for the authenticated user.

    GET /user/repos

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->list;

=item *

List public repositories for the specified user.

    GET /users/:user/repos

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->list( user => 'plu' );

=item *

List repositories for the specified org.

    GET /orgs/:org/repos

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->list( org => 'CPAN-API' );

=back

=head2 markdown

Provides access to L<Pithub::Markdown> setting the current repository as the
default context. This also sets the mode to default to 'gfm'.

=head2 pull_requests

Provides access to L<Pithub::PullRequests>.

=head2 releases

Provides access to L<Pithub::Repos::Releases>.

=head2 starring

Provides access to L<Pithub::Repos::Starring>.

=head2 stats

Provide access to L<Pithub::Repos::Stats>.

=head2 statuses

Provide access to L<Pithub::Repos::Statuses>.

=head2 tags

=over

=item *

List Tags

    GET /repos/:user/:repo/tags

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->tags( user => 'plu', repo => 'Pithub' );

=back

=head2 teams

=over

=item *

List Teams

    GET /repos/:user/:repo/teams

Examples:

    my $repos  = Pithub::Repos->new;
    my $result = $repos->teams( user => 'plu', repo => 'Pithub' );

=back

=head2 update

=over

=item *

Edit

    PATCH /repos/:user/:repo

Examples:

    # update a repo for the authenticated user
    my $repos  = Pithub::Repos->new;
    my $result = $repos->update(
        repo => 'Pithub',
        data => { description => 'Github API v3' },
    );

=back

=head2 watching

Provides access to L<Pithub::Repos::Watching>.

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
