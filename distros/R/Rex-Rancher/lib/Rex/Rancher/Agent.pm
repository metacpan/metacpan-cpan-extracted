# ABSTRACT: Rancher Kubernetes agent (worker node) installation

package Rex::Rancher::Agent;
our $VERSION = '0.001';
use v5.14.4;
use warnings;

use Rex::Commands::File;
use Rex::Commands::Run;
use Rex::Logger;
use Rex::Rancher::Server;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_agent
);

my %PATHS = (
  rke2 => {
    config_dir => '/etc/rancher/rke2',
    config_file => '/etc/rancher/rke2/config.yaml',
    registries_file => '/etc/rancher/rke2/registries.yaml',
    service => 'rke2-agent.service',
  },
  k3s => {
    config_dir => '/etc/rancher/k3s',
    config_file => '/etc/rancher/k3s/config.yaml',
    registries_file => '/etc/rancher/k3s/registries.yaml',
    service => 'k3s-agent.service',
  },
);

sub _paths {
  my ($distribution) = @_;
  return $PATHS{$distribution} || die "Unknown distribution: $distribution";
}


sub install_agent {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $server       = $opts{server} or die "server is required for install_agent";
  my $token        = $opts{token} or die "token is required for install_agent";
  my $version      = $opts{version};
  my $node_name    = $opts{node_name};

  my $paths = _paths($distribution);

  Rex::Logger::info("Installing $distribution agent to join $server");

  _write_config($paths, $distribution, %opts);
  _write_registries($paths, %opts);
  _run_installer($distribution, $version, $server, $token);
  _enable_service($paths);

  Rex::Logger::info("$distribution agent installed and running");
}

sub _write_config {
  my ($paths, $distribution, %opts) = @_;

  my $server    = $opts{server};
  my $token     = $opts{token};
  my $node_name = $opts{node_name};

  Rex::Logger::info("Writing $distribution agent config");

  run "mkdir -p $paths->{config_dir}", auto_die => 1;

  my @lines;
  push @lines, "server: $server";
  push @lines, "token: $token";
  push @lines, "node-name: $node_name" if $node_name;

  file $paths->{config_file},
    content => join("\n", @lines) . "\n";
}

sub _write_registries {
  my ($paths, %opts) = @_;

  return unless $opts{registries};

  Rex::Rancher::Server::_generate_registries_yaml(
    $paths->{config_dir} . '/', $opts{registries}
  );
}

sub _run_installer {
  my ($distribution, $version, $server, $token) = @_;

  Rex::Logger::info("Running $distribution agent installer");

  if ($distribution eq 'k3s') {
    my @env;
    push @env, "K3S_URL=$server";
    push @env, "K3S_TOKEN=$token";
    push @env, "INSTALL_K3S_VERSION=$version" if $version;
    my $env = join(" ", @env);
    run "curl -sfL https://get.k3s.io | $env sh -s - agent", auto_die => 1;
  }
  else {
    my @env;
    push @env, "INSTALL_RKE2_TYPE=agent";
    push @env, "INSTALL_RKE2_VERSION=$version" if $version;
    my $env = join(" ", @env);
    run "curl -sfL https://get.rke2.io | $env sh -", auto_die => 1;
  }
}

sub _enable_service {
  my ($paths) = @_;

  my $service = $paths->{service};
  Rex::Logger::info("Enabling and starting $service");
  run "systemctl enable $service", auto_die => 1;
  run "systemctl start $service", auto_die => 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Agent - Rancher Kubernetes agent (worker node) installation

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Rex::Rancher::Agent;

  # Join an RKE2 cluster as worker
  install_agent(
    server => 'https://10.0.0.1:9345',
    token  => 'K10abc123...',
  );

  # Join a K3s cluster as worker
  install_agent(
    distribution => 'k3s',
    server       => 'https://10.0.0.1:6443',
    token        => 'K10abc123...',
    version      => 'v1.28.4+k3s1',
    node_name    => 'worker-01',
  );

  # With pull-through registry cache
  install_agent(
    distribution   => 'rke2',
    server         => 'https://10.0.0.1:9345',
    token          => 'K10abc123...',
    registry_cache => 'http://cache.local:5000',
  );

=head1 DESCRIPTION

L<Rex::Rancher::Agent> installs and configures a Rancher Kubernetes worker
node for either RKE2 or K3s. It handles:

=over

=item * Writing C<config.yaml> with the server URL, token, and optional node name

=item * Writing C<registries.yaml> for private registry mirrors (optional)

=item * Running the official distribution installer via C<curl | sh>

=item * Enabling and starting the agent systemd service

=back

For RKE2 the installer is fetched from L<https://get.rke2.io> with
C<INSTALL_RKE2_TYPE=agent>. For K3s the installer from L<https://get.k3s.io>
is used with C<K3S_URL> and C<K3S_TOKEN> environment variables.

Registry configuration uses the same YAML structure and helper as
L<Rex::Rancher::Server>, so mirrors configured for the server are directly
reusable for agents.

=head2 install_agent

Write the agent configuration, optionally write C<registries.yaml>, run the
distribution installer, enable and start the agent service.

Required options:

=over

=item C<server>

URL of the server to join. For RKE2: C<https://SERVER_IP:9345>. For K3s:
C<https://SERVER_IP:6443>.

=item C<token>

Node join token. Obtain from the running server with
L<Rex::Rancher::Server/get_token>.

=back

Optional options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>.

=item C<version>

Pinned version string, e.g. C<v1.28.4+rke2r1> for RKE2 or C<v1.28.4+k3s1>
for K3s. If omitted, the latest stable release is installed.

=item C<node_name>

Override the Kubernetes node name. If omitted, the system hostname is used.

=item C<registries>

Private registry mirror configuration hashref. Same structure as
L<Rex::Rancher::Server/install_server>'s C<registries> option. Written to
C<registries.yaml> in the distribution config directory.

=back

  install_agent(
    distribution => 'rke2',
    server       => 'https://10.0.0.1:9345',
    token        => 'K10abc123...',
  );

=head1 SEE ALSO

L<Rex::Rancher>, L<Rex::Rancher::Server>, L<Rex::Rancher::Node>, L<Rex>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-rancher/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
