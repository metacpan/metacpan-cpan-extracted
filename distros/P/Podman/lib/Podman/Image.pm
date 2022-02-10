package Podman::Image;

use Mojo::Base 'Podman::Client';

use Archive::Tar;
use Exporter qw(import);
use Mojo::File qw(path tempfile);

our @EXPORT_OK = qw(build pull);

has 'name' => sub { return '' };

sub build {
  my ($name, $file, %options) = @_;

  my $self = __PACKAGE__->new;

  my $dir   = path($file)->dirname;
  my @files = map { $_->basename } @{path($dir)->list({dir => 1})->to_array};

  chdir $dir;
  my $archive = Archive::Tar->new();
  $archive->add_files(@files);

  my $archive_file = tempfile;
  $archive->write($archive_file);

  $self->post(
    'build',
    data       => $archive_file,
    parameters => {'file'         => path($file)->basename, 't' => $name, %options,},
    headers    => {'Content-Type' => 'application/x-tar'},
  );
  $self->get(sprintf "images/%s/exists", $name);

  return $self->name($name);
}

sub pull {
  my ($name, $tag, %options) = @_;

  my $self = __PACKAGE__->new;

  my $reference = sprintf "%s:%s", $name, $tag // 'latest';

  $self->post('images/pull', parameters => {reference => $reference, tlsVerify => 1, %options,});
  $self->get(sprintf "images/%s/exists", $name);

  return $self->name($name);
}

sub inspect {
  my $self = shift;

  my $data = $self->get(sprintf "images/%s/json", $self->name)->json;

  my $tag = (split /:/, $data->{RepoTags}->[0])[1];

  my %inspect = (Tag => $tag, Id => $data->{Id}, Created => $data->{Created}, Size => $data->{Size},);

  return \%inspect;
}

sub remove {
  my ($self, $force) = @_;

  $self->delete('images', parameters => {images => $self->name, force => $force // 0,});

  return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Podman::Image - Create and control image.

=head1 SYNOPSIS

    # Pull image from registry
    my $image = Podman::Image::pull('docker.io/library/hello-world');

    # Build new image from File
    my $image = Podman::Image::build('localhost/goodbye', '/tmp/Dockerfile');

    # Retrieve advanced image information
    my $info = $image->inspect;

    # Remove local stored image
    $image->remove();

=head1 DESCRIPTION

=head2 Inheritance

    Podman::Containers
        isa Podman::Client

L<Podman::Image> provides functionality to create and control an image.

=head1 ATTRIBUTES

L<Podman::Image> implements following attributes.

=head2 name

    my $image = Podman::Image->new();
    $image->name('docker.io/library/hello-world');

Unique image name or other identifier.

=head1 FUNCTIONS

L<Podman::Image> implements the following functions, which can be imported individually.

=head build

    use Podman::Image qw(build);
    my $image = build('localhost/goodbye', '/tmp/Dockerfile', %options);

Build and store named image from given build file and additional build options. All further recrusive available files in
the directory level of the build file are included.

=head2 pull

    use Podman::Image qw(pull);
    my $image = pull('docker.io/library/hello-world' 'latest', %options);

Pull named image with optional tag, defaults to C<latest> and additional options from registry into store.

=head1 METHODS

L<Podman::Image> implements following methods.

=head2 inspect

    my $Info = $image->inspect();

Return advanced image information.

=head2 remove

    $image->remove();

Remove image from store.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
