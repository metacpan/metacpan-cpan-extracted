package Podman::System;

use Mojo::Base 'Podman::Client';

use List::Util qw(sum);
use Scalar::Util qw(blessed);

sub disk_usage {
  my $self = shift;

  $self = __PACKAGE__->new unless blessed($self);

  my $data = $self->get('system/df')->json;

  my %disk_usage;
  for my $type (qw(Volumes Containers Images)) {
    my @data  = @{$data->{$type}};
    my %entry = (
      Total  => scalar @data,
      Active => sum(map { $_->{Containers} ? 1 : 0 } @data),
      Size   => sum(map { $_->{Size} } @data),
    );
    $disk_usage{$type} = \%entry;
  }

  return \%disk_usage;
}

sub info {
  my $self = shift;

  $self = __PACKAGE__->new unless blessed($self);

  return $self->get('info')->json;
}

sub version {
  my $self = shift;

  $self = __PACKAGE__->new unless blessed($self);

  my $data = $self->get('info')->json;

  my $version = $data->{version};
  delete $version->{GitCommit};
  delete $version->{Built};

  return $version;
}

sub prune {
  my $self = shift;

  $self = __PACKAGE__->new unless blessed($self);

  return $self->post('system/prune')->json;
}

1;

__END__

=encoding utf8

=head1 NAME

Podman::System - Service information.

=head1 SYNOPSIS

    # Object interface usage
    my $system  = Podman::System->new;
    my $version = $system->version;
    my $report  = $system->prune

    # Class interface usage
    my $disk    = Podman::System->disk_sage;
    my $version = Podman::System->version;

=head1 DESCRIPTION

=head2 Inheritance

    Podman::System
        isa Podman::Client

L<Podman::Service> provides system level information of the Podman service.

=head1 METHODS

L<Podman::System> implements following methods, which can be used as object or class methods.

=head2 disk_usage

    my $disk_usage = Podman::System->disk_usage;

Return information about disk usage for containers, images and volumes.

=head2 info

    my $info = Podman::System->info;

Return information on the system and libpod configuration.

=head2 prune

    my $report = Podman::System->prune;

Prune unused data and return report.

=head2 version

    my $version = Podman::System->version;

Obtain a dictionary of versions for the Podman service components.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
