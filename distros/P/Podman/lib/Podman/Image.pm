package Podman::Image;

##! Provides operations to create (build, pull) a new image and to manage it.

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

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

### Image name.
has 'Name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### Build new named image by given OCI file.
###
### All files placed in the OCI file directory are packed in a tar archive and
### attached to the request body.
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

### Pull named image with optional tag (default **latest**) from registry.
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

### Remove image from local store.
sub Remove {
    my ( $Self, $Force ) = @_;

    $Self->Client->Delete( sprintf "images/%s", $Self->Name );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
