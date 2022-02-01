package Podman::Containers;

##! Provides the operations against containers for a Podman service.
##!
##!     my $Containers = Podman::Containers->new(Client => Podman::Client->new());
##!
##!     # Display names and Ids of available containers.
##!     for my $Container (@{ $Containers->list() }) {
##!         my $Info = $Container->Inspect();
##!         printf "%s: %s\n", $Container->Id, $Info->{RepoTags}->[0];
##!     }

use strict;
use warnings;
use utf8;

use Moose;

use Podman::Client;
use Podman::Container;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is       => 'ro',
    isa      => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

### List all local stored containers.
### ```
###     my $List = Podman::Containers->new->List();
###     is(ref $List, 'ARRAY', 'Containers list ok.');
###
###     if ($List) {
###         is(ref $List->[0], 'Podman::Container', 'Containers list items ok.');
###     }
###
### ```
sub List {
    my $Self = shift;

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

__PACKAGE__->meta->make_immutable;

1;
