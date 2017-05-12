package Pithub::Repos::Releases::Assets;
$Pithub::Repos::Releases::Assets::VERSION = '0.01033';
our $AUTHORITY = 'cpan:PLU';

# ABSTRACT: Github v3 Repo Releases Assets API

use Moo;
use Carp qw(croak);
extends 'Pithub::Base';


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: name' unless $args{name};
    croak 'Missing key in parameters: release_id' unless $args{release_id};
    croak 'Missing key in parameters: data' unless $args{data};
    croak 'Missing key in parameters: content_type' unless $args{content_type};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method  => 'POST',
        path    => sprintf( '/repos/%s/%s/releases/%s/assets', delete $args{user}, delete $args{repo}, delete $args{release_id} ),
        host    => 'uploads.github.com',
        query   => { name => delete $args{name} },
        headers => {
            'Content-Type' => delete $args{content_type},
        },
        %args,
    );
}


sub delete {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: asset_id' unless $args{asset_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'DELETE',
        path   => sprintf( '/repos/%s/%s/releases/assets/%s', delete $args{user}, delete $args{repo}, delete $args{asset_id} ),
        %args,
    );
}


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: asset_id' unless $args{asset_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/releases/assets/%s', delete $args{user}, delete $args{repo}, delete $args{asset_id} ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: release_id' unless $args{release_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/releases/%s/assets', delete $args{user}, delete $args{repo}, delete $args{release_id} ),
        %args,
    );
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: asset_id' unless $args{asset_id};
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method  => 'PATCH',
        path    => sprintf( '/repos/%s/%s/releases/assets/%s', delete $args{user}, delete $args{repo}, delete $args{asset_id} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Repos::Releases::Assets - Github v3 Repo Releases Assets API

=head1 VERSION

version 0.01033

=head1 METHODS

=head2 create

=over

=item *

Upload a release asset.

    POST https://uploads.github.com/repos/:owner/:repo/releases/:id/assets?name=foo.zip

Examples:

    my $a = Pithub::Repos::Releases::Assets->new;
    my $result = $a->create(
        repo         => 'graylog2-server',
        user         => 'Graylog2',
        release_id   => 81148,
        name         => 'Some Asset',
        data         => 'the asset data',
        content_type => 'text/plain',
    );

=back

=head2 delete

=over

=item *

Delete a release asset.

    DELETE /repos/:owner/:repo/releases/assets/:id

Examples:

    my $a = Pithub::Repos::Releases::Assets->new;
    my $result = $a->delete(
        repo     => 'graylog2-server',
        user     => 'Graylog2',
        asset_id => 81148,
    );

=back

=head2 get

=over

=item *

Get a single release asset.

    GET /repos/:owner/:repo/releases/assets/:id

Examples:

    my $a = Pithub::Repos::Releases::Assets->new;
    my $result = $a->get(
        repo     => 'graylog2-server',
        user     => 'Graylog2',
        asset_id => 81148,
    );

=back

=head2 list

=over

=item *

List assets for a release.

    GET /repos/:owner/:repo/releases/:id/assets

Examples:

    my $a = Pithub::Repos::Releases::Assets->new;
    my $result = $a->list(
        repo       => 'graylog2-server',
        user       => 'Graylog2',
        release_id => 198110,
    );

=back

=head2 update

=over

=item *

Edit a release asset.

    PATCH /repos/:owner/:repo/releases/assets/:id

Examples:

    my $a = Pithub::Repos::Releases::Assets->new;
    my $result = $a->update(
        repo     => 'graylog2-server',
        user     => 'Graylog2',
        asset_id => 81148,
        data     => {
            name  => 'Some Name',
            label => 'Some Label',
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
