package Pithub::Events;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01040';
# ABSTRACT: Github v3 Events API

use Moo;
use Carp qw( croak );
extends 'Pithub::Base';


sub issue {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/issues/events', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub network {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/networks/%s/%s/events', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub org {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: org' unless $args{org};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/orgs/%s/events', delete $args{org} ),
        %args,
    );
}


sub org_for_user {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: org'  unless $args{org};
    croak 'Missing key in parameters: user' unless $args{user};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/users/%s/events/orgs/%s', delete $args{user}, delete $args{org} ),
        %args,
    );
}


sub public {
    my ( $self, %args ) = @_;
    return $self->request(
        method => 'GET',
        path   => '/events',
        %args,
    );
}


sub repos {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/events', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub user_performed {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: user' unless $args{user};
    my $path = sprintf( '/users/%s/events', delete $args{user} );
    if ( $args{public} ) {
        $path .= '/public';
    }
    return $self->request(
        method => 'GET',
        path   => $path,
        %args,
    );
}


sub user_received {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: user' unless $args{user};
    my $path = sprintf( '/users/%s/received_events', delete $args{user} );
    if ( $args{public} ) {
        $path .= '/public';
    }
    return $self->request(
        method => 'GET',
        path   => $path,
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Events - Github v3 Events API

=head1 VERSION

version 0.01040

=head1 METHODS

=head2 issue

=over

=item *

List issue events for a repository

    GET /repos/:user/:repo/issues/events

Examples:

    my $e      = Pithub::Events->new;
    my $result = $e->issue(
        user => 'plu',
        repo => 'Pithub',
    );

=back

=head2 network

=over

=item *

List public events for a network of repositories

    GET /networks/:user/:repo/events

Examples:

    my $e      = Pithub::Events->new;
    my $result = $e->network(
        user => 'plu',
        repo => 'Pithub',
    );

=back

=head2 org

=over

=item *

List public events for an organization

    GET /orgs/:org/events

Examples:

    my $e = Pithub::Events->new;
    my $result = $e->org( org => 'CPAN-API' );

=back

=head2 org_for_user

=over

=item *

List events for an organization

    GET /users/:user/events/orgs/:org

Examples:

    my $e = Pithub::Events->new;
    my $result = $e->org(
        org  => 'CPAN-API',
        user => 'plu',
    );

=back

=head2 public

=over

=item *

List public events

    GET /events

Examples:

    my $e      = Pithub::Events->new;
    my $result = $e->public;

=back

=head2 repos

=over

=item *

List repository events

    GET /repos/:user/:repo/events

Examples:

    my $e      = Pithub::Events->new;
    my $result = $e->repos(
        user => 'plu',
        repo => 'Pithub',
    );

=back

=head2 user_performed

=over

=item *

List events performed by a user

    GET /users/:user/events

If you are authenticated as the given user, you will see your
private events. Otherwise, you'll only see public events.

Examples:

    my $e = Pithub::Events->new;
    my $result = $e->user_performed( user => 'plu' );

    # List public events performed by a user
    my $e      = Pithub::Events->new;
    my $result = $e->user_performed(
        user   => 'plu',
        public => 1,
    );

=back

=head2 user_received

=over

=item *

List events that a user has received

    GET /users/:user/received_events

These are events that you've received by watching repos and
following users. If you are authenticated as the given user,
you will see private events. Otherwise, you'll only see
public events.

Examples:

    my $e = Pithub::Events->new;
    my $result = $e->user_received( user => 'plu' );

    # List public events that a user has received
    my $e      = Pithub::Events->new;
    my $result = $e->user_received(
        user   => 'plu',
        public => 1,
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
