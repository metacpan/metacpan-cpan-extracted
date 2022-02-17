package Podman::Container;

use Mojo::Base 'Podman::Client';

use Exporter qw(import);
use List::Util qw(first);

use Podman::Image;

our @EXPORT_OK = qw(create);

has 'name' => sub { return '' };

sub create {
  my ($name, $image, %options) = @_;

  my $self = __PACKAGE__->new;

  $self->post('containers/create',
    data => {image => ref $image eq 'Podman::Image' ? $image->name : $image, name => $name, %options});

  return $self->name($name);
}

sub inspect {
  my $self = shift;

  my $data   = $self->get(sprintf "containers/%s/json", $self->name)->json;
  my $status = $data->{State}->{Status};
  $status = $status eq 'configured' ? 'created' : $status;

  return {
    Id      => $data->{Id},
    Image   => Podman::Image->new(name => $data->{ImageName}),
    Created => $data->{Created},
    Status  => $status,
    Cmd     => $data->{Config}->{Cmd},
    Ports   => $data->{HostConfig}->{PortBindings},
  };
}

sub kill {
  my ($self, $signal) = @_;

  $signal //= 'SIGTERM';

  $self->post((sprintf "containers/%s/kill", $self->name), parameters => {signal => $signal});

  return 1;
}

sub remove {
  my ($self, $force) = @_;

  $self->delete((sprintf "containers/%s", $self->name), parameters => {force => $force});

  return 1;
}

sub stats {
  my $self = shift;

  my $data  = $self->get('containers/stats', parameters => {stream => 0})->json;
  my $stats = first { $_->{Name} eq $self->name } @{$data->{Stats}};

  return unless $stats;
  return {
    CpuPercent => $stats->{CPU},
    MemUsage   => $stats->{MemUsage},
    MemPercent => $stats->{MemPerc},
    NetIO      => (sprintf "%d / %d", $stats->{NetInput},   $stats->{NetOutput}),
    BlockIO    => (sprintf "%d / %d", $stats->{BlockInput}, $stats->{BlockOutput}),
    PIDs       => $stats->{PIDs},
  };
}

sub systemd {
  my $self = shift;

  my $data = $self->get(sprintf "generate/%s/systemd", $self->name)->json;

  return (values %{$data})[0];
}

for my $name (qw(pause restart start stop unpause)) {
  Mojo::Util::monkey_patch(__PACKAGE__, $name,
    sub { my $self = shift; $self->post(sprintf "containers/%s/%s", $self->name, $name); return 1; });
}

1;

__END__

=encoding utf8

=head1 NAME

Podman::Container - Create and control container.

=head1 SYNOPSIS

    # Create container
    use Podman::Container qw(create);
    my $container = create('nginx', 'docker.io/library/nginx');

    # Start container
    $container->start;

    # Stop container
    $container->stop;

    # Kill container
    $container->kill;

=head1 DESCRIPTION

=head2 Inheritance

    Podman::Container
        isa Podman::Client

L<Podman::Container> provides functionallity to create and control a container.

=head1 ATTRIBUTES

L<Podman::Container> implements following attributes.

=head2 name

    my $container = Podman::Container->new;
    $container->name('docker.io/library/hello-world');

Unique image name or (short) identifier.

=head1 FUNCTIONS

L<Podman::Container> implements the following functions, which can be imported individually.

=head2 create

    use Podman::Container qw(create);
    my $container = create(
        'nginx',
        'docker.io/library/nginx',
        tty         => 1,
        interactive => 1,
    );

Create named container by given image <Podman::Image> object or name and additional create options.

=head1 METHODS

L<Podman::Container> implements following methods.

=head2 inspect

    my $info = $container->inspect;

Return advanced container information.

=head2 kill

    $container->kill('SIGKILL');

Send signal to container, defaults to 'SIGTERM'.

=head2 pause

    $container->pause;

Pause running container.

=head2 remove

    my $force = 1;
    $container->remove($force);

Remove stopped container. Takes additional argument force to remove even running container.

=head2 start

    $container->start;

Start stopped container.

=head2 stats

    my $stats = $container->stats;
    for my $property (keys %{$stats}) {
        say $property . ': ' . $stats->{$property};
    }

Return current usage statistics of running container.

=head2 stop

    $container->stop;

Stop running container.

=head2 systemd

    my $unit = $container->systemd;

Generate unit file to supervise container by systemd.

=head2 unpause

    $container->unpause;

Resume paused container.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
