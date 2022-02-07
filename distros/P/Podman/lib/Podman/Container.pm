package Podman::Container;

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

has 'Name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub Create {
    my ( $Package, $Name, $Image, $Client, %Options ) = @_;

    return if Scalar::Util::blessed($Package);

    $Client //= Podman::Client->new();

    my $Response = $Client->Post(
        'containers/create',
        Data => {
            image => $Image,
            name  => $Name,
            %Options
        },
        Headers => {
            'Content-Type' => 'application/json'
        }
    );

    return if !$Response;

    return __PACKAGE__->new(
        Client => $Client,
        Name   => $Name,
    );
}

sub Delete {
    my ( $Self, $Force ) = @_;

    $Self->Client->Delete(
        ( sprintf "containers/%s", $Self->Name ),
        Parameters => {
            force => $Force,
        }
    );

    return 1;
}

sub Inspect {
    my $Self = shift;

    my $Data = $Self->Client->Get( sprintf "containers/%s/json", $Self->Name );

    my $State = $Data->{State}->{Status};
    $State = $State eq 'configured' ? 'created' : $State;
    my %Inspect = (
        Id    => $Data->{Id},
        Image => Podman::Image->new(
            Name   => $Data->{ImageName},
            Client => $Self->Client
        ),
        Created => $Data->{Created},
        Status  => $State,
        Cmd     => $Data->{Config}->{Cmd},
        Ports   => $Data->{HostConfig}->{PortBindings},
    );

    return \%Inspect;
}

sub Kill {
    my ( $Self, $Signal ) = @_;

    $Signal //= 'SIGTERM';

    $Self->Client->Post(
        ( sprintf "containers/%s/kill", $Self->Name ),
        Parameters => {
            signal => $Signal,
        },
    );

    return 1;
}

sub Start {
    my ( $Self, $Name ) = @_;

    $Self->Client->Post( sprintf "containers/%s/start", $Self->Name );

    return 1;
}

sub Stop {
    my ( $Self, $Name ) = @_;

    $Self->Client->Post( sprintf "containers/%s/stop", $Self->Name );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Podman::Container - Contol container.

=head1 SYNOPSIS

    # Create container
    my $Container = Podman::Container->Create('nginx', 'docker.io/library/nginx');

    # Start container
    $Container->Start();

    # Stop container
    $Container->Stop();

    # Kill container
    $Container->Kill();

=head1 DESCRIPTION

L<Podman::Container> provides functionallity to control a container.

=head1 ATTRIBUTES

=head2 Name

    my $Container = Podman::Image->new( Name => 'my_container' );

Unique image name or other identifier.

=head2 Client

    my $Client = Podman::Client->new(
        Connection => 'http+unix:///var/cache/podman.sock' );
    my $Container = Podman::Container->new( Client => $Client );

Optional L<Podman::Client> object.

=head1 METHODS

=head2 Create

    my $Container = Podman::Container->Create(
        'nginx',
        'docker.io/library/nginx',
        undef,
        tty         => 1,
        interactive => 1,
    );

Create named container by given image name. Optional arguments are
L<Podman::Client> object and further container options.

=head2 Inspect

    my $Info = $Container->Inspect();

Return advanced container information.

=head2 Kill

    $Container->Kill('SIGKILL');

Send signal to container, defaults to 'SIGTERM'.

=head2 Stop

    $Container->Start();

Start stopped container.

=head2 Stop

    $Container->Stop();

Stop running container.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
