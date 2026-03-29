# ABSTRACT: Cilium CNI installation for Rancher Kubernetes distributions

package Rex::Rancher::Cilium;
our $VERSION = '0.001';
use v5.14.4;
use warnings;

use Rex::Commands::File;
use Rex::Commands::Gather;
use Rex::Commands::Run;
use Rex::Logger;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_cilium
  upgrade_cilium
);

use constant CILIUM_VERSION     => '1.17.0';
use constant CILIUM_CLI_VERSION => 'v0.16.23';



sub install_cilium {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $version      = $opts{version}      // CILIUM_VERSION;
  my $cli_version  = $opts{cli_version}  // CILIUM_CLI_VERSION;
  my $api_server   = $opts{api_server};

  Rex::Logger::info("Installing Cilium $version on $distribution cluster");

  _install_cilium_cli($cli_version);

  my $paths = _paths_for($distribution);
  my $values_file = _write_helm_values($distribution, $version, $paths);

  my @cmd = (
    "cilium install",
    "--version $version",
    "--helm-values $values_file",
  );
  push @cmd, "--set kubeProxyReplacement=true" if $distribution eq 'rke2';
  push @cmd, "--api-server $api_server" if $api_server;

  my $env = "KUBECONFIG=$paths->{kubeconfig}";
  my $install_cmd = "$env " . join(" ", @cmd) . " 2>&1";

  Rex::Logger::info("Running: $install_cmd");
  my $out = run $install_cmd, auto_die => 0;

  if ($? != 0) {
    # "cannot re-use a name that is still in use" means Cilium is already
    # installed (Helm release exists) — treat as success for idempotent re-deploys.
    if (($out // '') =~ /cannot re-use a name/i) {
      Rex::Logger::info("  Cilium already installed (Helm release exists), skipping");
      return;
    }
    die "cilium install failed: " . ($out // '') . "\n";
  }

  Rex::Logger::info("Cilium $version installed on $distribution cluster");
}


sub upgrade_cilium {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $version      = $opts{version}      // CILIUM_VERSION;
  my $cli_version  = $opts{cli_version}  // CILIUM_CLI_VERSION;
  my $api_server   = $opts{api_server};

  Rex::Logger::info("Upgrading Cilium to $version on $distribution cluster");

  _install_cilium_cli($cli_version);

  my $paths = _paths_for($distribution);
  my $values_file = _write_helm_values($distribution, $version, $paths);

  my @cmd = (
    "cilium upgrade",
    "--version $version",
    "--helm-values $values_file",
  );
  push @cmd, "--api-server $api_server" if $api_server;

  my $env = "KUBECONFIG=$paths->{kubeconfig}";
  my $upgrade_cmd = "$env " . join(" ", @cmd);

  Rex::Logger::info("Running: $upgrade_cmd");
  run $upgrade_cmd, auto_die => 1;

  Rex::Logger::info("Cilium upgraded to $version on $distribution cluster");
}

#
# Cilium CLI installation
#

sub _install_cilium_cli {
  my ($cli_version) = @_;

  # Check if already installed at the right version
  my $current = run "cilium version --client 2>/dev/null | head -1", auto_die => 0;
  if ($current && $current =~ /\Q$cli_version\E/) {
    Rex::Logger::info("Cilium CLI $cli_version already installed");
    return;
  }

  Rex::Logger::info("Installing Cilium CLI $cli_version");

  my $arch = run "uname -m", auto_die => 1;
  chomp $arch;
  $arch = 'amd64' if $arch eq 'x86_64';
  $arch = 'arm64' if $arch eq 'aarch64';

  my $url = "https://github.com/cilium/cilium-cli/releases/download/$cli_version/cilium-linux-$arch.tar.gz";

  run "curl -fsSL '$url' -o /tmp/cilium-linux-$arch.tar.gz", auto_die => 1;
  run "tar xzf /tmp/cilium-linux-$arch.tar.gz -C /tmp cilium", auto_die => 1;
  run "mv /tmp/cilium /usr/local/bin/cilium", auto_die => 1;
  run "chmod 755 /usr/local/bin/cilium", auto_die => 1;
  run "rm -f /tmp/cilium-linux-$arch.tar.gz", auto_die => 0;

  Rex::Logger::info("Cilium CLI $cli_version installed to /usr/local/bin/cilium");
}

#
# Distribution-specific paths
#

sub _paths_for {
  my ($distribution) = @_;

  if ($distribution eq 'rke2') {
    return {
      kubeconfig  => '/etc/rancher/rke2/rke2.yaml',
      cni_bin     => '/opt/cni/bin',
      cni_conf    => '/etc/cni/net.d',
      socket_path => '/run/k3s/containerd/containerd.sock',
    };
  }
  elsif ($distribution eq 'k3s') {
    return {
      kubeconfig  => '/etc/rancher/k3s/k3s.yaml',
      cni_bin     => '/opt/cni/bin',
      cni_conf    => '/etc/cni/net.d',
      socket_path => '/run/k3s/containerd/containerd.sock',
    };
  }
  else {
    die "Unknown distribution: $distribution (expected 'rke2' or 'k3s')\n";
  }
}

#
# Helm values generation
#

sub _write_helm_values {
  my ($distribution, $version, $paths) = @_;

  my $values_file = "/tmp/cilium-values-$distribution.yaml";

  my $cni_exclusive = $distribution eq 'rke2' ? 'false' : 'true';

  my $values = <<YAML;
cni:
  binPath: $paths->{cni_bin}
  confPath: $paths->{cni_conf}
  exclusive: $cni_exclusive
ipam:
  mode: kubernetes
YAML

  if ($distribution eq 'rke2') {
    $values .= <<'YAML';
kubeProxyReplacement: true
k8sServiceHost: 127.0.0.1
k8sServicePort: "6443"
operator:
  replicas: 1
YAML
  }
  elsif ($distribution eq 'k3s') {
    $values .= <<'YAML';
operator:
  replicas: 1
YAML
  }

  file $values_file, content => $values;

  Rex::Logger::info("Wrote Helm values to $values_file");
  return $values_file;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Cilium - Cilium CNI installation for Rancher Kubernetes distributions

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Rex::Rancher::Cilium;

  # Install Cilium on an RKE2 cluster (defaults to version 1.17.0)
  install_cilium(
    distribution => 'rke2',
  );

  # Install Cilium on a K3s cluster with explicit version
  install_cilium(
    distribution => 'k3s',
    version      => '1.17.0',
    cli_version  => 'v0.16.23',
  );

  # Upgrade an existing Cilium installation
  upgrade_cilium(
    distribution => 'rke2',
    version      => '1.17.0',
  );

=head1 DESCRIPTION

L<Rex::Rancher::Cilium> provides Cilium CNI installation and upgrade for
Rancher Kubernetes distributions (RKE2 and K3s). All operations are run
on the remote server host via SSH.

=head2 Prerequisites

The server must already be running with C<cni: none> and
C<disable-kube-proxy: true> in its C<config.yaml> so that Cilium can
own the CNI and kube-proxy roles. L<Rex::Rancher::Server/install_server>
sets these options by default when C<cilium =E<gt> 1>.

=head2 Helm values

Distribution-specific Helm values are written to
C</tmp/cilium-values-E<lt>distE<gt>.yaml>:

=over

=item RKE2

C<kubeProxyReplacement: true>, C<k8sServiceHost: 127.0.0.1>,
C<k8sServicePort: "6443">, C<cni.exclusive: false>, C<operator.replicas: 1>.

=item K3s

C<cni.exclusive: true>, C<operator.replicas: 1>.

=back

Both distributions use C<ipam.mode: kubernetes> and share the same CNI
binary/config paths (C</opt/cni/bin>, C</etc/cni/net.d>).

=head2 Default versions

The module ships with pinned defaults for reproducibility:
Cilium C<1.17.0> and Cilium CLI C<v0.16.23>. Override with the
C<version> and C<cli_version> options.

=head1 FUNCTIONS

=head2 install_cilium(%opts)

Install Cilium CNI on a Rancher Kubernetes cluster (RKE2 or K3s).

The Cilium CLI binary is downloaded from GitHub to C</usr/local/bin/cilium>
on the remote host (skipped if the correct version is already present).
Distribution-appropriate Helm values are generated and written to
C</tmp/cilium-values-E<lt>distE<gt>.yaml>, then C<cilium install> is invoked
with those values.

For RKE2, C<kubeProxyReplacement=true> is passed to enable Cilium's
eBPF-based kube-proxy replacement (the RKE2 server config must have
C<disable-kube-proxy: true> for this to work). For K3s, C<exclusive: true>
is set for the CNI plugin to ensure K3s's built-in Flannel does not
conflict.

Options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>.

=item C<version>

Cilium version to install, e.g. C<1.17.0>. Default: C<1.17.0>.

=item C<cli_version>

Cilium CLI version to download, e.g. C<v0.16.23>. Default: C<v0.16.23>.

=item C<api_server>

Kubernetes API server URL, passed as C<--api-server> to the CLI. Optional;
the CLI uses the kubeconfig's server address if omitted.

=back

=head2 upgrade_cilium(%opts)

Upgrade an existing Cilium installation to a new version using
C<cilium upgrade>. The Cilium CLI is updated first if needed. The same
Helm values generation logic as L</install_cilium> is used.

Options are the same as L</install_cilium>.

  upgrade_cilium(
    distribution => 'rke2',
    version      => '1.17.0',
  );

=head1 SEE ALSO

L<Rex::Rancher>, L<Rex::Rancher::Server>, L<Rex>,
L<https://docs.cilium.io/>

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
