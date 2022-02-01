package Podman::Images;

##! Provides the operations against images for a Podman service.
##!
##!     # Display names and Ids of available images.
##!     for my $Image (@{ Podman::Images->new->List() }) {
##!         my $Info = $Image->Inspect();
##!         printf "%s: %s\n", $Image->Id, $Info->{RepoTags}->[0];
##!     }

use strict;
use warnings;
use utf8;

use Moose;

use Podman::Client;
use Podman::Image;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

### List all local stored images.
### ```
###     use Podman::Client;
###
###     my $Images = Podman::Images->new(Client => Podman::Client->new());
###
###     my $List = $Images->List();
###     is(ref $List, 'ARRAY', 'Images list ok.');
###
###     if ($List) {
###         is(ref $List->[0], 'Podman::Image', 'Images list items ok.');
###     }
###
### ```
sub List {
    my $Self = shift;

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

__PACKAGE__->meta->make_immutable;

1;
