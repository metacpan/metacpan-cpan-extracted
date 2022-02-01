package Podman::System;

##! Provide system level information for the Podman service.

use strict;
use warnings;
use utf8;

use Moose;

use List::Util ();

use Podman::Client;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

###  Return information about disk usage for containers, images and volumes.
###
### ```
###     use Podman::Client;
###
###     my $System = Podman::System->new(Client => Podman::Client->new());
###
###     my $DiskUsage = $System->DiskUsage();
###     is(ref $DiskUsage, 'HASH', 'DiskUsage object ok.');
###
###     my @Keys = sort keys %{ $DiskUsage };
###     my @Expected = (
###         'Containers',
###         'Images',
###         'Volumes',
###     );
###     is_deeply(\@Keys, \@Expected, 'DiskUsage object complete.');
### ```
sub DiskUsage {
    my $Self = shift;

    my $Data = $Self->Client->Get('system/df');

    my %DiskUsage;
    for my $Type (qw(Volumes Containers Images)) {
        my @TypeData = @{ $Data->{$Type} };
        my %Entry    = (
            Total  => scalar @TypeData,
            Active =>
              List::Util::sum( map { $_->{Containers} ? 1 : 0 } @TypeData ),
            Size => List::Util::sum( map { $_->{Size} } @TypeData ),
        );
        $DiskUsage{$Type} = \%Entry;
    }

    return \%DiskUsage;
}

### Obtain a dictionary of versions for the Podman components.
### ```
###     use Podman::Client;
###
###     my $System = Podman::System->new(Client => Podman::Client->new());
###
###     my $Version = $System->Version();
###     is(ref $Version, 'HASH', 'Version object ok.');
###     is($Version->{Version}, '3.0.1', 'Version number ok.');
### ```
sub Version {
    my $Self = shift;

    my $Data = $Self->Client->Get('info');

    my $Version = $Data->{version};
    delete $Version->{GitCommit};
    delete $Version->{Built};

    return $Version;
}

__PACKAGE__->meta->make_immutable;

1;
