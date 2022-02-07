package Podman::Image;

use strict;
use warnings;
use utf8;

use Moose;

use Archive::Tar;
use Cwd            ();
use File::Basename ();
use File::Temp     ();
use Path::Tiny;
use Scalar::Util;

use Podman::Client;

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

sub Build {
    my ( $Package, $Name, $File, $Client ) = @_;

    return if Scalar::Util::blessed($Package);

    my $Dir = File::Basename::dirname($File);

    my ( @Files, $DirHandle );
    chdir $Dir;
    opendir $DirHandle, Cwd::getcwd();
    @Files = grep { !m{^\.{1,2}$} } readdir $DirHandle;
    closedir $DirHandle;

    my $Archive = Archive::Tar->new();
    $Archive->add_files(@Files);

    my $ArchiveFile = File::Temp->new();
    $Archive->write( $ArchiveFile->filename );

    $Client //= Podman::Client->new();

    my $Response = $Client->Post(
        'build',
        Data       => $ArchiveFile,
        Parameters => {
            'file' => File::Basename::basename($File),
            't'    => $Name,
        },
        Headers => {
            'Content-Type' => 'application/x-tar'
        },
    );

    return if !$Response;

    return __PACKAGE__->new(
        Client => $Client,
        Name   => $Name,
    );
}

sub Pull {
    my ( $Package, $Name, $Tag, $Client ) = @_;

    return if Scalar::Util::blessed($Package);

    $Name = sprintf "%s:%s", $Name, $Tag // 'latest';

    $Client //= Podman::Client->new();

    my $Response = $Client->Post(
        'images/pull',
        Parameters => {
            reference => $Name,
            tlsVerify => 1,
        }
    );

    return if !$Response;

    return __PACKAGE__->new(
        Client => $Client,
        Name   => $Name,
    );
}

sub Inspect {
    my $Self = shift;

    my $Data = $Self->Client->Get( sprintf "images/%s/json", $Self->Name );

    my ($Tag) = $Data->{RepoTags}->[0] =~ m{.+:(.+)};

    my %Inspect = (
        Tag     => $Tag,
        Id      => $Data->{Id},
        Created => $Data->{Created},
        Size    => $Data->{Size}
    );

    return \%Inspect;
}

sub Remove {
    my ( $Self, $Force ) = @_;

    $Self->Client->Delete( sprintf "images/%s", $Self->Name );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Podman::Image - Control image.

=head1 SYNOPSIS

    # Pull image from iregistry
    my $Image = Podman::Image->Pull('docker.io/library/hello-world');

    # Build new image from File
    my $Image = Podman::Image->Build('localhost/goodbye', '/tmp/Dockerfile');

    # Retrieve advanced image information
    my $info = $Image->Inspect();

    # Remove local stored image
    $Image->Remove();

=head1 DESCRIPTION

L<Podman::Image> provides functionality to control an image.

=head1 ATTRIBUTES

=head2 Name

    my $Image = Podman::Image->new( Name => 'localhost/goodbye' );

Unique image name or other identifier.

=head2 Client

    my $Client = Podman::Client->new(
        Connection => 'http+unix:///var/cache/podman.sock' );
    my $Image = Podman::Image->new( Client => $Client );

Optional L<Podman::Client> object.

=head1 METHODS

=head2 Build

    my $Image = Podman::Image->Build('localhost/goodbye', '/tmp/Dockerfile');

Build a named image by a given build file and store it. All further content in
the build file directory is used as well to create the new image.

=head2 Inspect

    my $Info = $Image->Inspect();

Return advanced image information.

=head2 Pull

    my $Image = Podman::Image->Pull('docker.io/library/hello-world');

Pull named image from registry into store.

=head2 Remove

    $Image->Remove();

Remove image from store.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
