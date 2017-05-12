package Pithub::Issues::Milestones;
$Pithub::Issues::Milestones::VERSION = '0.01033';
our $AUTHORITY = 'cpan:PLU';

# ABSTRACT: Github v3 Issue Milestones API

use Moo;
use Carp qw(croak);
extends 'Pithub::Base';


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'POST',
        path   => sprintf( '/repos/%s/%s/milestones', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub delete {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: milestone_id' unless $args{milestone_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/repos/%s/%s/milestones/%s', delete $args{user}, delete $args{repo}, delete $args{milestone_id} ),
        %args,
    );
}


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: milestone_id' unless $args{milestone_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/milestones/%s', delete $args{user}, delete $args{repo}, delete $args{milestone_id} ),
        %args
    );
}


sub list {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/milestones', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: milestone_id' unless $args{milestone_id};
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'PATCH',
        path   => sprintf( '/repos/%s/%s/milestones/%s', delete $args{user}, delete $args{repo}, delete $args{milestone_id} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Issues::Milestones - Github v3 Issue Milestones API

=head1 VERSION

version 0.01033

=head1 METHODS

=head2 create

=over

=item *

Create a milestone

    POST /repos/:user/:repo/milestones

Examples:

    my $m = Pithub::Issues::Milestones->new;
    my $result = $m->create(
        repo => 'Pithub',
        user => 'plu',
        data => {
            description => 'String',
            due_on      => 'Time',
            state       => 'open or closed',
            title       => 'String'
        }
    );

=back

=head2 delete

=over

=item *

Delete a milestone

    DELETE /repos/:user/:repo/milestones/:id

Examples:

    my $m = Pithub::Issues::Milestones->new;
    my $result = $m->delete(
        repo => 'Pithub',
        user => 'plu',
        milestone_id => 1,
    );

=back

=head2 get

=over

=item *

Get a single milestone

    GET /repos/:user/:repo/milestones/:id

Examples:

    my $m = Pithub::Issues::Milestones->new;
    my $result = $m->get(
        repo => 'Pithub',
        user => 'plu',
        milestone_id => 1,
    );

=back

=head2 list

=over

=item *

List milestones for an issue

    GET /repos/:user/:repo/milestones

Examples:

    my $m = Pithub::Issues::Milestones->new;
    my $result = $m->list(
        repo => 'Pithub',
        user => 'plu',
    );

=back

=head2 update

=over

=item *

Update a milestone

    PATCH /repos/:user/:repo/milestones/:id

Examples:

    my $m = Pithub::Issues::Milestones->new;
    my $result = $m->update(
        repo => 'Pithub',
        user => 'plu',
        data => {
            description => 'String',
            due_on      => 'Time',
            state       => 'open or closed',
            title       => 'String'
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
