# ABSTRACT: Rancher Kubernetes agent (worker node) installation

package Rex::Rancher::Agent;
our $VERSION = '0.002';
use v5.14.4;
use warnings;

use Rex::Commands::File;
use Rex::Commands::Run;
use Rex::Logger;
use Rex::Rancher::Server;
use YAML::PP;

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
    env_file => '/etc/default/rke2-agent',
  },
  k3s => {
    config_dir => '/etc/rancher/k3s',
    config_file => '/etc/rancher/k3s/config.yaml',
    registries_file => '/etc/rancher/k3s/registries.yaml',
    service => 'k3s-agent.service',
    # No env_file: see Rex::Rancher::Server::_nvidia_runtime_path.
  },
);

sub _paths {
  my ($distribution) = @_;
  return $PATHS{$distribution} || die "Unknown distribution: $distribution";
}


sub install_agent {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $server       = $opts{server} or die "server is required for install_agent\n";
  my $token        = $opts{token} or die "token is required for install_agent\n";
  my $version      = $opts{version};
  my $node_name    = $opts{node_name};
  my $method       = Rex::Rancher::Server::_install_method($opts{install_method}, $version);

  my $paths = _paths($distribution);

  Rex::Logger::info("Installing $distribution agent to join $server");

  _write_config($paths, $distribution, %opts);
  _write_registries($paths, %opts);
  # Before the installer and the first start, as on the server.
  Rex::Rancher::Server::_nvidia_runtime_path($paths) if $opts{nvidia_runtime_path};
  _run_installer($distribution, $version, $server, $method);
  Rex::Rancher::Server::_verify_installed_version($distribution, $version);
  _enable_service($paths, $distribution);

  Rex::Logger::info("$distribution agent installed and running");
}

# Same keys on rke2 and k3s agents; node-label as in
# Rex::Rancher::Server::_build_server_config.
sub _build_agent_config {
  my (%opts) = @_;

  my %config = (
    server => $opts{server},
    token  => $opts{token},
  );
  $config{'node-name'} = $opts{node_name} if $opts{node_name};

  if (my $node_labels = $opts{node_labels}) {
    my @labels = ref $node_labels eq 'ARRAY' ? @{$node_labels} : ($node_labels);
    $config{'node-label'} = \@labels;
  }

  return \%config;
}

sub _write_config {
  my ($paths, $distribution, %opts) = @_;

  Rex::Logger::info("Writing $distribution agent config");

  run "mkdir -p $paths->{config_dir}", auto_die => 1;

  Rex::Rancher::Server::_write_secret_file($paths->{config_file},
    YAML::PP->new->dump_string(_build_agent_config(%opts)));
}

sub _write_registries {
  my ($paths, %opts) = @_;

  return unless $opts{registries};

  Rex::Rancher::Server::_generate_registries_yaml(
    $paths->{config_dir} . '/', $opts{registries}
  );
}

sub _run_installer {
  my ($distribution, $version, $server, $method) = @_;

  Rex::Logger::info("Running $distribution agent installer");

  if (($method // 'script') eq 'artifact') {
    my $spec = Rex::Rancher::Server::_fetch_artifacts($distribution, $version);
    if ($distribution eq 'k3s') {
      run Rex::Rancher::Server::_k3s_binary_place_cmd($spec), auto_die => 1;
      run Rex::Rancher::Server::_k3s_artifact_install_cmd($spec, $server, $version, 'agent'),
        auto_die => 1;
    }
    else {
      run Rex::Rancher::Server::_rke2_artifact_install_cmd($spec, $version, 'agent'),
        auto_die => 1;
    }
    return;
  }

  run _installer_cmd($distribution, $version, $server), auto_die => 1;
}

# The token is NOT passed here for either distribution: _write_config has
# already put it into config.yaml, and anything on this line shows up in ps.
sub _installer_cmd {
  my ($distribution, $version, $server) = @_;

  if ($distribution eq 'k3s') {
    # INSTALL_K3S_SKIP_START: the script's own `systemctl restart` of the
    # Type=notify unit blocks until the agent has joined, forever for one
    # that cannot reach $server; _enable_service starts it bounded instead.
    my @env;
    push @env, "K3S_URL=$server";
    push @env, "INSTALL_K3S_VERSION=$version" if $version;
    push @env, 'INSTALL_K3S_SKIP_START=true';
    my $env = join(" ", @env);
    return "curl -sfL https://get.k3s.io | $env sh -s - agent";
  }
  my @env;
  push @env, "INSTALL_RKE2_TYPE=agent";
  push @env, "INSTALL_RKE2_VERSION=$version" if $version;
  my $env = join(" ", @env);
  return "curl -sfL https://get.rke2.io | $env sh -";
}

sub _enable_service {
  my ($paths, $distribution) = @_;

  my $service = $paths->{service};
  # k3s: restart, as the install script did before INSTALL_K3S_SKIP_START,
  # so a re-run still picks up a new binary and config.yaml. rke2's
  # installer never started the agent.
  my $verb = ($distribution // '') eq 'k3s' ? 'restart' : 'start';
  Rex::Logger::info("Enabling and starting $service");
  run "systemctl enable $service", auto_die => 1;
  # --no-block, same as the server: a start that fails or outlasts systemd's
  # activation timeout ends in _wait_for_service, which reports the journal,
  # instead of a bare systemctl error (or, for an agent that cannot reach
  # its server, a Type=notify start that never returns).
  run "systemctl $verb --no-block $service", auto_die => 1;
  Rex::Rancher::Server::_wait_for_service($service);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Agent - Rancher Kubernetes agent (worker node) installation

=head1 VERSION

version 0.002

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

  # With a pull-through registry mirror
  install_agent(
    distribution => 'rke2',
    server       => 'https://10.0.0.1:9345',
    token        => 'K10abc123...',
    registries   => {
      mirrors => { 'docker.io' => { endpoint => ['http://cache.local:5000'] } },
    },
  );

=head1 DESCRIPTION

L<Rex::Rancher::Agent> installs and configures a Rancher Kubernetes worker
node for either RKE2 or K3s. It handles:

=over

=item * Writing C<config.yaml> with the server URL, token, and optional node name
and node labels

=item * Writing C<registries.yaml> for private registry mirrors (optional)

=item * Running the official distribution installer via C<curl | sh>, or from a
checksum-verified release artifact (C<install_method =E<gt> 'artifact'>)

=item * Enabling and starting the agent systemd service, and waiting until it
is active (journal tail in the error if it is not)

=back

For RKE2 the installer is fetched from L<https://get.rke2.io> with
C<INSTALL_RKE2_TYPE=agent>. For K3s the installer from L<https://get.k3s.io>
is used with the C<K3S_URL> environment variable and
C<INSTALL_K3S_SKIP_START>: instead of the script's own blocking restart, the
agent is restarted with C<--no-block> and waited on for at most 10 minutes,
so an agent that cannot reach its server dies with its journal instead of
hanging the deploy. For both distributions the
token is read from C<config.yaml> and never passed on the installer command
line, where C<ps> would show it. C<config.yaml> and C<registries.yaml> are
written C<0600 root:root>.

Registry configuration uses the same YAML structure and helper as
L<Rex::Rancher::Server>, so mirrors configured for the server are directly
reusable for agents.

=head2 install_agent

Write the agent configuration, optionally write C<registries.yaml>, run the
distribution installer, enable and start the agent service, and wait until
C<systemctl is-active> reports it active (up to 10 minutes). A service that
ends up C<failed> or never gets active dies with the last 50 lines of its
journal in the message.

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
for K3s. If omitted, the latest stable release is installed. When given, the
installed binary's C<--version> is checked against it after the installer
ran, and a mismatch dies (on RKE2 before the service is started; the K3s
install script has already started it).

=item C<install_method>

C<script> (default: C<curl | sh>, unchanged) or C<artifact>: download the
release artifact for the node's architecture on the host, verify it against
the official C<sha256sum-ARCH.txt> (a mismatch dies), and install from it.
Requires C<version>. Details, including the RPM-host caveat for RKE2, in
L<Rex::Rancher::Server/install_server>.

=item C<node_name>

Override the Kubernetes node name. If omitted, the system hostname is used.

=item C<node_labels>

Node labels applied at join time (C<node-label> in C<config.yaml>), as an
arrayref of C<key=value> strings. Same as
L<Rex::Rancher::Server/install_server>'s C<node_labels>; like there, labels
are only read when the agent registers, not on a re-run against a node that
already joined.

=item C<registries>

Private registry mirror configuration hashref. Same structure as
L<Rex::Rancher::Server/install_server>'s C<registries> option. Written to
C<registries.yaml> in the distribution config directory.

=item C<nvidia_runtime_path>

If true, and C<nvidia-container-runtime> is on the host's C<PATH>, write a
C<PATH=> line to C</etc/default/rke2-agent> before the installer runs, so rke2
finds a host-installed NVIDIA runtime at service start. Same behaviour as
L<Rex::Rancher::Server/install_server>'s C<nvidia_runtime_path>; no effect on
k3s. Default: C<0>; L<Rex::Rancher/rancher_deploy_agent> turns it on for
C<gpu =E<gt> 1, gpu_setup =E<gt> 0>.

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
