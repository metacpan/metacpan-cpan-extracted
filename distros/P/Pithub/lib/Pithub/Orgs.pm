package Pithub::Orgs;
our $AUTHORITY = 'cpan:PLU';
# ABSTRACT: Github v3 Orgs API

use Moo;
our $VERSION = '0.01040';

use Carp qw( croak );
use Pithub::Orgs::Members;
use Pithub::Orgs::Teams;
extends 'Pithub::Base';


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: org' unless $args{org};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/orgs/%s', delete $args{org} ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    if ( my $user = delete $args{user} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/users/%s/orgs', $user ),
            %args,
        );
    }
    return $self->request(
        method => 'GET',
        path   => '/user/orgs',
        %args,
    );
}


sub members {
    return shift->_create_instance('Pithub::Orgs::Members', @_);
}


sub teams {
    return shift->_create_instance('Pithub::Orgs::Teams', @_);
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: org' unless $args{org};
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    return $self->request(
        method => 'PATCH',
        path   => sprintf( '/orgs/%s', delete $args{org} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Orgs - Github v3 Orgs API

=head1 VERSION

version 0.01040

=head1 METHODS

=head2 get

=over

=item *

Get an organization

    GET /orgs/:org

Examples:

    my $o = Pithub::Orgs->new;
    my $result = $o->get( org => 'CPAN-API' );

=back

=head2 list

=over

=item *

List all public organizations for a user.

    GET /users/:user/orgs

Examples:

    my $o = Pithub::Orgs->new;
    my $result = $o->list( user => 'plu' );

=item *

List public and private organizations for the authenticated user.

    GET /user/orgs

Examples:

    my $o = Pithub::Orgs->new;
    my $result = $o->list;

=back

=head2 members

Provides access to L<Pithub::Orgs::Members>.

=head2 teams

Provides access to L<Pithub::Orgs::Teams>.

=head2 update

=over

=item *

Edit an organization

    PATCH /orgs/:org

Examples:

    my $o = Pithub::Orgs->new;
    my $result = $o->update(
        org  => 'CPAN-API',
        data => {
            billing_email => 'support@github.com',
            blog          => 'https://github.com/blog',
            company       => 'GitHub',
            email         => 'support@github.com',
            location      => 'San Francisco',
            name          => 'github',
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
