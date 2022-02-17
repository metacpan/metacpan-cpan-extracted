package Podman;

use strict;
use warnings;
use utf8;

use Exporter qw(import);

use Podman::Container;
use Podman::Containers;
use Podman::Image;
use Podman::Images;
use Podman::System;

our @EXPORT_OK   = qw(build containers create images pull version);
our %EXPORT_TAGS = (all => [@EXPORT_OK],);

sub build      { Podman::Image::build(@_); }
sub containers { Podman::Containers->list }
sub create     { Podman::Container::create(@_); }
sub images     { Podman::Images->list }
sub pull       { Podman::Image::pull(@_); }
sub version    { Podman::System->version }

1;

__END__

=encoding utf8

=head1 NAME

Podman - Library of bindings to use the RESTful API of L<https://podman.io> service.

=head1 SYNOPSIS

    # Build and store image
    use Podman qw(build);
    my $image = build('localhost/goodbye', '/tmp/goodbye/Dockerfile');

    # List stored images name
    say $_->name for $Podman::images;

    # Show version information
    use Podman qw(:all);
    say version->{Version};

=head1 DESCRIPTION

L<Podman> is a library of bindings to use the RESTful API of L<https://podman.io> service. It is currently under
development and contributors are welcome!

=head1 FUNCTIONS

L<Podman::Image> implements the following functions, which can be imported individually or colletctively.

=head2 build

    my $image  = Podman::build('localhost/goodbye', '/tmp/goodbye/Dockerfile', %opts);

Build and store named image from given build file and additional build options.

=head2 containers

    use Podman qw(containers);
    say $_->inspect->{Id} for containers->each;

Return L<Mojo::Collection> of available containers.

=head2 create

    use Podman qw(:all);
    my $container = create('nginx', 'docker.io/library/nginx', %opts);

Create named container based on given image and additional create options.

=head2 images

    say Podman::images->size;

Return L<Mojo::Collection> of stored images.

=head2 pull

    my $image = Podman::pull('docker.io/library/hello-world');

Pull and store named image from registry.

=head2 version

    use Podman qw(version);
    say version->{APIVersion};

Obtain a dictionary of versions for the Podman service components.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/tschaefer/podman-perl>, L<https://docs.podman.io/en/v3.0/_static/api.html>

=cut
