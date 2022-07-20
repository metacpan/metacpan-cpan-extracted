package Pithub::PullRequests::Reviewers;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01037';
# ABSTRACT: Github v3 Pull Request Review Requests API

use Moo;
use Carp qw( croak );
extends 'Pithub::Base';


sub delete {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id' unless $args{pull_request_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/repos/%s/%s/pulls/%s/requested_reviewers', delete $args{user}, delete $args{repo}, delete $args{pull_request_id} ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id' unless $args{pull_request_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/pulls/%s/requested_reviewers', delete $args{user}, delete $args{repo}, delete $args{pull_request_id} ),
        %args,
    );
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: pull_request_id' unless $args{pull_request_id};
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'POST',
        path   => sprintf( '/repos/%s/%s/pulls/%s/requested_reviewers', delete $args{user}, delete $args{repo}, delete $args{pull_request_id} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::PullRequests::Reviewers - Github v3 Pull Request Review Requests API

=head1 VERSION

version 0.01037

=head1 METHODS

=head2 delete

=over

=item *

Remove requested reviewers

    DELETE /repos/:user/:repo/pulls/:id/requested_reviewers

Examples:

    my $c = Pithub::PullRequests::Reviewers->new;
    my $result = $c->delete(
        repo            => 'Pithub',
        user            => 'plu',
        pull_request_id => 1,
    );

=back

=head2 list

=over

=item *

List requested_reviewers for a pull request

    GET /repos/:user/:repo/pulls/:id/requested_reviewers

Examples:

    my $c = Pithub::PullRequests::Reviewers->new;
    my $result = $c->list(
        repo            => 'Pithub',
        user            => 'plu',
        pull_request_id => 1,
    );

=back

=head2 update

=over

=item *

Request reviewers for a pull request

    POST /repos/:user/:repo/pulls/:id/requested_reviewers

Examples:

    my $c = Pithub::PullRequests::Reviewers->new;
    my $result = $c->update(
        repo       => 'Pithub',
        user       => 'plu',
        pull_request_id => 1,
        data       => { reviewers => ['octocat'] },
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
