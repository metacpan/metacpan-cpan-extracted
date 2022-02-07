package Podman::System;

use strict;
use warnings;
use utf8;

use Moose;

use List::Util ();
use Scalar::Util ();

use Podman::Client;

has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

sub DiskUsage {
    my $Self = shift;

    $Self = __PACKAGE__->new() if !Scalar::Util::blessed($Self);

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

sub Version {
    my $Self = shift;

    $Self = __PACKAGE__->new() if !Scalar::Util::blessed($Self);


    my $Data = $Self->Client->Get('info');

    my $Version = $Data->{version};
    delete $Version->{GitCommit};
    delete $Version->{Built};

    return $Version;
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Podman::System - Service information.

=head1 SYNOPSIS

    # Create and use system controller
    my $System = Podman::System->new();
    my $Version = $System->Version();

    # Get disk usage info
    my $Disk = Podman::System->DiskUsage();

    # Get components version
    Podman::System->Version();

=head1 DESCRIPTION

L<Podman::Service> provides system level information for a Podman service.

=head1 ATTRIBUTES

=head2 Client

    my $Client = Podman::Client->new(
        Connection => 'http+unix:///var/cache/podman.sock' );
    my $Images = Podman::Images->new( Client => $Client );

Optional L<Podman::Client> object.

=head1 METHODS

=head2 DiskUsage

    my $DiskUsage = Podman::System->DiskUsage();

Return information about disk usage for containers, images and volumes.

=head2 Version

    my $Version = Podman::System->Version();

Obtain a dictionary of versions for the Podman service components.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
