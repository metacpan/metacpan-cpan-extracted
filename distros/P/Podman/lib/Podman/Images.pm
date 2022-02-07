package Podman::Images;

use strict;
use warnings;
use utf8;

use Moose;

use Scalar::Util;

use Podman::Client;
use Podman::Image;

has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

sub List {
    my $Self = shift;

    $Self = __PACKAGE__->new() if !Scalar::Util::blessed($Self);

    my $List = $Self->Client->Get(
        'images/json',
        Parameters => {
            all => 1
        },
    );

    my @List = ();
    @List =
      map {
        my ($Name) = split /:/, $_->{RepoTags}->[0];
        Podman::Image->new(
            Client => $Self->Client,
            Name   => $Name,
        )
      } @{$List};

    return \@List;
}

sub Prune {
    my $Self = shift;

    $Self = __PACKAGE__->new() if !Scalar::Util::blessed($Self);

    $Self->Client->Post('images/prune');

    return 1; 
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Podman::Images - Manage images.

=head1 SYNOPSIS

    # Create and use containers controller
    my $Images = Podman::Images->new();
    $Images->List();

    # List local stored images
    my $List = Podman::Images->List();

    # Prune unused images
    Podman::Images->Prune;

=head1 DESCRIPTION

L<Podman::Images> lists images and prunes unused ones.

=head1 ATTRIBUTES

=head2 Client

    my $Client = Podman::Client->new(
        Connection => 'http+unix:///var/cache/podman.sock' );
    my $Images = Podman::Images->new( Client => $Client );

Optional L<Podman::Client> object.

=head1 METHODS

=head2 List

    my $List = Podman::Images->List();

Returns a list of L<Podman::Image> of stored images.

=head2 Prune

    Podman::Images->Prune();

Prune all unused stored images.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
