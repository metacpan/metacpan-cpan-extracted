package Podman::Container;

use strict;
use warnings;
use utf8;

use Moose;

use Scalar::Util;

use Podman::Client;
use Podman::Image;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

### Image identifier, short identifier or name.
has 'Name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### Create new named container of given image with given command.
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

### Delete container, optional force deleting if current in use.
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

### Display container configuration.
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

### Kill container.
sub Kill {
    my ( $Self, $Signal, $All ) = @_;

    $Signal //= 'SIGTERM';

    $Self->Client->Post(
        ( sprintf "containers/%s/kill", $Self->Name ),
        Parameters => {
            signal => $Signal,
            all    => $All,
        },
    );

    return 1;
}

### Start container.
sub Start {
    my ( $Self, $Name ) = @_;

    $Self->Client->Post( sprintf "containers/%s/start", $Self->Name );

    return 1;
}

### Stop container.
sub Stop {
    my ( $Self, $Name ) = @_;

    $Self->Client->Post( sprintf "containers/%s/stop", $Self->Name );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
