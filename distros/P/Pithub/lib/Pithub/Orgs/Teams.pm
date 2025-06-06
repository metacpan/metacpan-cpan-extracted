package Pithub::Orgs::Teams;
our $AUTHORITY = 'cpan:PLU';

# ABSTRACT: Github v3 Org Teams API

use Moo;

our $VERSION = '0.01043';

use Carp qw( carp croak );

extends 'Pithub::Base';


sub add_member {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: user'    unless $args{user};
    carp q{"Add team member" API is deprecated. Use add_membership method.};
    return $self->request(
        method => 'PUT',
        path   => sprintf(
            '/teams/%s/members/%s', delete $args{team_id}, delete $args{user}
        ),
        %args,
    );
}


sub add_membership {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: user'    unless $args{user};
    croak 'Missing key in parameters: data'    unless $args{data};
    return $self->request(
        method => 'PUT',
        path   => sprintf(
            '/teams/%s/memberships/%s', delete $args{team_id},
            delete $args{user}
        ),
        %args,
    );
}


sub add_repo {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: repo'    unless $args{repo};
    croak 'Missing key in parameters: org'     unless $args{org};
    return $self->request(
        method => 'PUT',
        path   => sprintf(
            '/teams/%s/repos/%s/%s',
            delete $args{team_id},
            delete $args{org},
            delete $args{repo}
        ),
        %args,
    );
}


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: org' unless $args{org};
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    return $self->request(
        method => 'POST',
        path   => sprintf( '/orgs/%s/teams', delete $args{org} ),
        %args,
    );
}


## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/teams/%s', delete $args{team_id} ),
        %args,
    );
}
## use critic


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/teams/%s', delete $args{team_id} ),
        %args,
    );
}


sub has_repo {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: repo'    unless $args{repo};
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/teams/%s/repos/%s', delete $args{team_id}, delete $args{repo}
        ),
        %args,
    );
}


sub is_member {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: user'    unless $args{user};
    return $self->request(
        method => 'GET',
        path   => sprintf(
            '/teams/%s/members/%s', delete $args{team_id}, delete $args{user}
        ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: org' unless $args{org};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/orgs/%s/teams', delete $args{org} ),
        %args,
    );
}


sub list_members {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/teams/%s/members', delete $args{team_id} ),
        %args,
    );
}


sub list_repos {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/teams/%s/repos', delete $args{team_id} ),
        %args,
    );
}


sub remove_member {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: user'    unless $args{user};
    carp
        q{"Remove team member" API is deprecated. Use remove_membership method.};
    return $self->request(
        method => 'DELETE',
        path   => sprintf(
            '/teams/%s/members/%s', delete $args{team_id}, delete $args{user}
        ),
        %args,
    );
}


sub remove_membership {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: user'    unless $args{user};
    return $self->request(
        method => 'DELETE',
        path   => sprintf(
            '/teams/%s/memberships/%s', delete $args{team_id},
            delete $args{user}
        ),
        %args,
    );
}


sub remove_repo {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: repo'    unless $args{repo};
    return $self->request(
        method => 'DELETE',
        path   => sprintf(
            '/teams/%s/repos/%s', delete $args{team_id}, delete $args{repo}
        ),
        %args,
    );
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: team_id' unless $args{team_id};
    croak 'Missing key in parameters: data (hashref)'
        unless ref $args{data} eq 'HASH';
    return $self->request(
        method => 'PATCH',
        path   => sprintf( '/teams/%s', delete $args{team_id} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Orgs::Teams - Github v3 Org Teams API

=head1 VERSION

version 0.01043

=head1 METHODS

=head2 add_member

=over

The "Add team member" API (described below) is deprecated and is
scheduled for removal in the next major version of the API. We
recommend using the Add team membership API instead. It allows
you to invite new organization members to your teams.

In order to add a user to a team, the authenticated user must have
'admin' permissions to the team or be an owner of the org that the
team is associated with.

    PUT /teams/:id/members/:user

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->add_member(
        team_id => 1,
        user    => 'plu',
    );

=back

=head2 add_membership

=over

If the user is already a member of the team's organization, this
endpoint will add the user to the team. In order to add a membership
between an organization member and a team, the authenticated user
must be an organization owner or a maintainer of the team.

    PUT /teams/:id/memberships/:user

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->add_membership(
        team_id => 1,
        user    => 'plu',
        data    => {
            role => 'member',
        }
    );

=back

=head2 add_repo

=over

In order to add a repo to a team, the authenticated user must be
an owner of the org that the team is associated with.

    PUT /teams/:id/repos/:repo

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->add_repo(
        team_id => 1,
        repo    => 'some_repo',
        org => 'our_organization',
    );

=back

=head2 create

=over

In order to create a team, the authenticated user must be an
owner of the given organization.

    POST /orgs/:org/teams

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->create(
        org  => 'CPAN-API',
        data => {
            name       => 'new team',
            permission => 'push',
            repo_names => ['github/dotfiles']
        }
    );

=back

=head2 delete

=over

In order to delete a team, the authenticated user must be an owner
of the org that the team is associated with.

    DELETE /teams/:id

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->delete( team_id => 1 );

=back

=head2 get

=over

Get team

    GET /teams/:id

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->get( team_id => 1 );

=back

=head2 has_repo

=over

Get team repo

    GET /teams/:id/repos/:repo

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->has_repo(
        team_id => 1,
        repo    => 'some_repo',
    );

=back

=head2 is_member

=over

In order to get if a user is a member of a team, the authenticated
user must be a member of the team.

    GET /teams/:id/members/:user

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->is_member(
        team_id => 1,
        user    => 'plu',
    );

=back

=head2 list

=over

List teams

    GET /orgs/:org/teams

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->list( org => 'CPAN-API' );

=back

=head2 list_members

=over

In order to list members in a team, the authenticated user must be
a member of the team.

    GET /teams/:id/members

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->list_members( team_id => 1 );

=back

=head2 list_repos

=over

List team repos

    GET /teams/:id/repos

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->list_repos( team_id => 1 );

=back

=head2 remove_member

=over

The "Remove team member" API (described below) is deprecated and
is scheduled for removal in the next major version of the API. We
recommend using the Remove team membership API instead. It allows
you to remove both active and pending memberships.

In order to remove a user from a team, the authenticated user must
have 'admin' permissions to the team or be an owner of the org that
the team is associated with. NOTE: This does not delete the user,
it just remove them from the team.

    DELETE /teams/:id/members/:user

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->remove_member(
        team_id => 1,
        user    => 'plu',
    );

=back

=head2 remove_membership

=over

In order to remove a membership between a user and a team,
the authenticated user must have 'admin' permissions to
the team or be an owner of the organization that the team
is associated with. NOTE: This does not delete the user,
it just removes their membership from the team.

    DELETE /teams/:id/memberships/:user

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->remove_membership(
        team_id => 1,
        user    => 'plu',
    );

=back

=head2 remove_repo

=over

In order to remove a repo from a team, the authenticated user must be
an owner of the org that the team is associated with.

    DELETE /teams/:id/repos/:repo

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->remove_repo(
        team_id => 1,
        repo    => 'some_repo',
    );

=back

=head2 update

=over

In order to edit a team, the authenticated user must be an owner
of the org that the team is associated with.

    PATCH /teams/:id

Examples:

    my $t = Pithub::Orgs::Teams->new;
    my $result = $t->update(
        team_id => 1,
        data    => {
            name       => 'new team name',
            permission => 'push',
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
