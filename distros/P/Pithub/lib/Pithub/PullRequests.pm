package Pithub::PullRequests;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01042';

# ABSTRACT: Github v3 Pull Requests API

use Moo;
use Carp                            qw( croak );
use Pithub::PullRequests::Comments  ();
use Pithub::PullRequests::Reviewers ();
extends 'Pithub::Base';


sub comments {
    return shift->_create_instance( Pithub::PullRequests::Comments::, @_ );
}


sub reviewers {
    return shift->_create_instance( Pithub::PullRequests::Reviewers::, @_ );
}


sub commits {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id'
        unless $args{pull_request_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/pulls/%s/commits', delete $args{user},
            delete $args{repo},              delete $args{pull_request_id}
        ),
        %args,
    );
}


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'POST',
        path   => sprintf(
            '/repos/%s/%s/pulls', delete $args{user}, delete $args{repo}
        ),
        %args,
    );
}


sub files {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id'
        unless $args{pull_request_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/pulls/%s/files', delete $args{user},
            delete $args{repo},            delete $args{pull_request_id}
        ),
        %args,
    );
}


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id'
        unless $args{pull_request_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/pulls/%s', delete $args{user}, delete $args{repo},
            delete $args{pull_request_id}
        ),
        %args,
    );
}


sub is_merged {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id'
        unless $args{pull_request_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/pulls/%s/merge', delete $args{user},
            delete $args{repo},            delete $args{pull_request_id}
        ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/repos/%s/%s/pulls', delete $args{user}, delete $args{repo}
        ),
        params => {
            per_page => 100,
            page     => delete $args{page},
        },
        %args,
    );
}


sub merge {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id'
        unless $args{pull_request_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'PUT',
        path   => sprintf(
            '/repos/%s/%s/pulls/%s/merge', delete $args{user},
            delete $args{repo},            delete $args{pull_request_id}
        ),
        %args,
    );
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id'
        unless $args{pull_request_id};
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'PATCH',
        path   => sprintf(
            '/repos/%s/%s/pulls/%s', delete $args{user}, delete $args{repo},
            delete $args{pull_request_id}
        ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::PullRequests - Github v3 Pull Requests API

=head1 VERSION

version 0.01042

=head1 METHODS

=head2 comments

Provides access to L<Pithub::PullRequests::Comments>.

=head2 reviewers

Provides access to L<Pithub::PullRequests::Reviewers>.

=head2 commits

=over

=item *

List commits on a pull request

    GET /repos/:user/:repo/pulls/:id/commits

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->commits(
        user            => 'plu',
        repo            => 'Pithub',
        pull_request_id => 1
    );

=back

=head2 create

=over

=item *

Create a pull request

    POST /repos/:user/:repo/pulls

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->create(
        user   => 'plu',
        repo => 'Pithub',
        data   => {
            base  => 'master',
            body  => 'Please pull this in!',
            head  => 'octocat:new-feature',
            title => 'Amazing new feature',
        }
    );

=back

=head2 files

=over

=item *

List pull requests files

    GET /repos/:user/:repo/pulls/:id/files

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->files(
        user            => 'plu',
        repo            => 'Pithub',
        pull_request_id => 1,
    );

=back

=head2 get

=over

=item *

Get a single pull request

    GET /repos/:user/:repo/pulls/:id

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->get(
        user            => 'plu',
        repo            => 'Pithub',
        pull_request_id => 1,
    );

=back

=head2 is_merged

=over

=item *

Get if a pull request has been merged

    GET /repos/:user/:repo/pulls/:id/merge

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->is_merged(
        user            => 'plu',
        repo            => 'Pithub',
        pull_request_id => 1,
    );

=back

=head2 list

=over

=item *

List pull requests

    GET /repos/:user/:repo/pulls

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->list(
        user => 'plu',
        repo => 'Pithub',
        page => 2,
            # Defaults to page 1, and defaults to a limit of 100 results
    );

=back

=head2 merge

=over

=item *

Merge a pull request

    PUT /repos/:user/:repo/pulls/:id/merge

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->merge(
        user            => 'plu',
        repo            => 'Pithub',
        pull_request_id => 1,
    );

=back

=head2 update

=over

=item *

Update a pull request

    PATCH /repos/:user/:repo/pulls/:id

Examples:

    my $p = Pithub::PullRequests->new;
    my $result = $p->update(
        user            => 'plu',
        repo            => 'Pithub',
        pull_request_id => 1,
        data            => {
            base  => 'master',
            body  => 'Please pull this in!',
            head  => 'octocat:new-feature',
            title => 'Amazing new feature',
        }
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
