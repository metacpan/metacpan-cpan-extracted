package Podman::Containers;

use strict;
use warnings;
use utf8;

use Moose;

use Scalar::Util;

use Podman::Client;
use Podman::Container;

has 'Client' => (
    is       => 'ro',
    isa      => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

sub List {
    my $Self = shift;

    $Self = __PACKAGE__->new() if !Scalar::Util::blessed($Self);

    my $List = $Self->Client->Get(
        'containers/json',
        Parameters => {
            all => 1
        },
    );

    my @List = map {
        Podman::Container->new(
            Client => $Self->Client,
            Name   => $_->{Names}->[0],
        )
    } @{$List};

    return \@List;
}

sub Prune {
    my $Self = shift;

    $Self = __PACKAGE__->new() if !Scalar::Util::blessed($Self);

    $Self->Client->Post('containers/prune');

    return 1; 
}


__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Podman::Containers - Manage containers.

=head1 SYNOPSIS

    # Create and use containers controller
    my $Containers = Podman::Containers->new();
    $Containers->list();

    # List available containers
    my $List = Podman::Containers->List();

    # Prune stopped containers
    Podman::Containers->Prune;


=head1 DESCRIPTION

L<Podman::Images> lists all available containers and prunes stopped ones.

=head1 ATTRIBUTES

=head2 Client

    my $Client = Podman::Client->new(
        Connection => 'http+unix:///var/cache/podman.sock' );
    my $Images = Podman::Images->new( Client => $Client );

Optional L<Podman::Client> object.

=head1 METHODS

=head2 List

    my $List = Podman::Containers->List();

Returns a list of L<Podman::Container> available.

=head2 Prune

    Podman::Containers->->Prune();

Prune all stopped containers.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
