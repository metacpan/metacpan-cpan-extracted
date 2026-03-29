# ABSTRACT: Rancher Kubernetes (RKE2/K3s) deployment automation for Rex

package Rex::Rancher;

use v5.14.4;
use warnings;

our $VERSION = '0.001';

use Rex::Rancher::Node;
use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::Cilium;
use Rex::Rancher::K8s;
use Rex::Logger;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  rancher_deploy_server
  rancher_deploy_agent
  wait_for_api
  untaint_node
  deploy_nvidia_device_plugin
);


sub _check_connection {
  my $conn = Rex::get_current_connection() or return;
  return if Rex::is_local();

  my $type = eval { $conn->{conn}->get_connection_type() } // '';
  return if $type eq 'LibSSH';

  my $sftp = eval { Rex::get_sftp() };
  return if $sftp && eval { $sftp->stat('/'); 1 };

  die "This host has no SFTP subsystem and you are not using the LibSSH "
    . "connection backend.\n"
    . "Add 'set connection => \"LibSSH\"' to your Rexfile and install "
    . "Rex::LibSSH to deploy to SFTP-less hosts.\n";
}

sub rancher_deploy_server {
  my (%opts) = @_;
  my $distribution    = $opts{distribution}    // 'rke2';
  my $kubeconfig_file = $opts{kubeconfig_file};

  _check_connection();
  prepare_node(%opts);

  _gpu_setup_if_requested($distribution, %opts);

  install_server(%opts);

  # Fetch and save kubeconfig locally, then wait for the API from this machine.
  # install_server only waits for the kubeconfig file to appear on the remote;
  # actual API readiness is confirmed here via Rex::Rancher::K8s::wait_for_api.
  my $local_kc = _save_kubeconfig_locally($distribution, $kubeconfig_file, %opts);
  wait_for_api(kubeconfig => $local_kc) if $local_kc;

  install_cilium(distribution => $distribution);

  if ($opts{gpu} && $local_kc) {
    deploy_nvidia_device_plugin(kubeconfig => $local_kc);
  }

  Rex::Logger::info("$distribution server deployment complete");
}


sub rancher_deploy_agent {
  my (%opts) = @_;
  my $distribution = $opts{distribution} // 'rke2';

  prepare_node(%opts);

  _gpu_setup_if_requested($distribution, %opts);

  install_agent(%opts);

  Rex::Logger::info("$distribution agent deployment complete");
}

sub _gpu_setup_if_requested {
  my ($distribution, %opts) = @_;

  return unless $opts{gpu};

  my $loaded = eval { require Rex::GPU; Rex::GPU->import(); 1 };
  unless ($loaded) {
    die "gpu => 1 requested but Rex::GPU is not installed. Install the Rex-GPU distribution.\n";
  }

  Rex::GPU::gpu_setup(
    containerd_config => $distribution,
    reboot            => ($opts{reboot} // 0),
  );
}

sub _save_kubeconfig_locally {
  my ($distribution, $output_file, %opts) = @_;

  return unless $output_file;

  my $content = eval { get_kubeconfig($distribution) };
  unless ($content) {
    Rex::Logger::info("Could not fetch kubeconfig from remote — skipping local save", "warn");
    return;
  }

  # RKE2/K3s writes 127.0.0.1 in the kubeconfig; patch to the real address
  my $server_addr = _kubeconfig_server_addr(%opts);
  if ($server_addr) {
    $content =~ s{https://127\.0\.0\.1:(\d+)}{https://$server_addr:$1}g;
  }

  open(my $fh, '>', $output_file)
    or do {
      Rex::Logger::info("Could not write kubeconfig to $output_file: $!", "warn");
      return;
    };
  print $fh $content;
  close $fh;

  Rex::Logger::info("Kubeconfig saved to $output_file");
  return $output_file;
}

sub _kubeconfig_server_addr {
  my (%opts) = @_;
  return $opts{kubeconfig_server} if $opts{kubeconfig_server};
  my $tls_san = $opts{tls_san};
  return unless $tls_san;
  my @sans = ref $tls_san eq 'ARRAY' ? @{$tls_san} : split(/,/, $tls_san);
  return $sans[0] if @sans;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher - Rancher Kubernetes (RKE2/K3s) deployment automation for Rex

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Rex -feature => ['1.4'];
  use Rex::Rancher;

  # Deploy RKE2 control plane (no GPU)
  task "deploy_server", sub {
    rancher_deploy_server(
      distribution    => 'rke2',
      hostname        => 'cp-01',
      domain          => 'k8s.example.com',
      token           => 'my-secret',
      tls_san         => 'k8s.example.com',
      kubeconfig_file => "$ENV{HOME}/.kube/mycluster.yaml",
    );
  };

  # Deploy RKE2 control plane with GPU support
  task "deploy_gpu_server", sub {
    rancher_deploy_server(
      distribution    => 'rke2',
      gpu             => 1,    # requires Rex::GPU installed
      reboot          => 1,    # reboot after driver install (first deploy)
      hostname        => 'gpu-cp-01',
      domain          => 'k8s.example.com',
      token           => 'my-secret',
      tls_san         => 'gpu-cp-01.k8s.example.com',
      kubeconfig_file => "$ENV{HOME}/.kube/gpu-cluster.yaml",
    );
  };

  # Deploy K3s worker with GPU support
  task "deploy_gpu_worker", sub {
    rancher_deploy_agent(
      distribution => 'k3s',
      gpu          => 1,    # requires Rex::GPU installed
      hostname     => 'gpu-01',
      domain       => 'k8s.example.com',
      server       => 'https://10.0.0.1:6443',
      token        => 'K10...',
    );
  };

  # Deploy a single-node cluster (control plane + workloads on same node)
  task "deploy_single_node", sub {
    rancher_deploy_server(
      distribution    => 'rke2',
      token           => 'my-secret',
      tls_san         => '10.0.0.1',
      kubeconfig_file => "$ENV{HOME}/.kube/single.yaml",
    );
    # Remove control-plane taint so workloads can be scheduled
    untaint_node(kubeconfig => "$ENV{HOME}/.kube/single.yaml");
  };

=head1 DESCRIPTION

L<Rex::Rancher> provides complete, zero-touch Kubernetes cluster deployment
for Rancher distributions (RKE2 and K3s) using the L<Rex> orchestration
framework. It handles everything from raw Linux node preparation through to
a running CNI and GPU device plugin.

GPU support is optional. Pass C<gpu =E<gt> 1> and install L<Rex::GPU>
separately. Rex::Rancher works identically for non-GPU nodes.

When deploying a GPU server node, the full pipeline runs automatically:

=over

=item 1. B<Node preparation> — hostname, timezone, locale, NTP, swap off,
kernel modules (br_netfilter, overlay), sysctl for Kubernetes networking.

=item 2. B<GPU setup> (C<gpu =E<gt> 1>) — NVIDIA driver via DKMS, optional
reboot, Container Toolkit, CDI specs, containerd runtime config. Handled by
L<Rex::GPU>.

=item 3. B<Cluster bring-up> — write config, run RKE2 or K3s install script,
wait for kubeconfig file on the remote host, fetch and save it locally,
wait for API server readiness via L<Kubernetes::REST>.

=item 4. B<Cilium CNI> — Cilium CLI installed on the remote host, Cilium
deployed with distribution-appropriate Helm values.

=item 5. B<NVIDIA device plugin> (C<gpu =E<gt> 1> + C<kubeconfig_file>) — DaemonSet
applied via the Kubernetes API, wait for C<nvidia.com/gpu> capacity on the
node. No C<kubectl> required anywhere.

=back

All Kubernetes API operations (steps 3 and 5) run locally on the machine
executing Rex using L<Kubernetes::REST> and L<IO::K8s>. No C<kubectl>
binary is needed on the remote host.

This distribution supports hosts without an SFTP subsystem (common on
Hetzner dedicated servers). Use C<set connection =E<gt> "LibSSH"> and
install L<Rex::LibSSH>.

For fine-grained control, use the individual modules directly:

=over

=item L<Rex::Rancher::Node> — Node preparation

=item L<Rex::Rancher::Server> — Control plane installation and config retrieval

=item L<Rex::Rancher::Agent> — Worker node installation

=item L<Rex::Rancher::Cilium> — Cilium CNI installation and upgrade

=item L<Rex::Rancher::K8s> — Kubernetes API operations (device plugin, readiness, untaint)

=back

=head2 rancher_deploy_server(%opts)

Full control plane deployment in a single call: prepare the node, optionally
set up GPU support, install the Kubernetes distribution, wait for the API,
install Cilium CNI, and deploy the NVIDIA device plugin.

When C<gpu =E<gt> 1> is passed and L<Rex::GPU> is installed, GPU detection
and driver installation are performed automatically as step 2 before the
cluster is brought up. After Cilium is running, the NVIDIA device plugin
DaemonSet is deployed via the local Kubernetes API (no C<kubectl> required
on the remote host) and the function waits for C<nvidia.com/gpu> resources
to appear on the node.

The full pipeline for a GPU server deployment:

=over

=item 1. C<prepare_node> — hostname, timezone, swap off, kernel modules, sysctl

=item 2. C<gpu_setup> (only with C<gpu =E<gt> 1>) — driver + toolkit + CDI + containerd config

=item 3. C<install_server> — write config, run installer, wait for kubeconfig file

=item 4. Fetch kubeconfig locally, patch C<127.0.0.1> to the real server address,
save to C<kubeconfig_file>, wait for API with L<Rex::Rancher::K8s/wait_for_api>

=item 5. C<install_cilium> — install Cilium CLI on remote, apply via C<cilium install>

=item 6. C<deploy_nvidia_device_plugin> (only with C<gpu =E<gt> 1> and C<kubeconfig_file>)

=back

Options:

=over

=item C<distribution>

Kubernetes distribution to install. C<rke2> (default) or C<k3s>.

=item C<gpu>

If true, detect GPUs and run the full GPU setup pipeline via L<Rex::GPU>
before installing the Kubernetes distribution. Requires L<Rex::GPU> to be
installed. Default: C<0>.

=item C<reboot>

If true, reboot the host after GPU driver installation and wait for it to
come back before proceeding. Only meaningful with C<gpu =E<gt> 1>. Required
on first deploy when C<nouveau> was previously loaded. Default: C<0>.

=item C<hostname>

Short hostname to set on the node (optional). If omitted, the existing
hostname is left unchanged.

=item C<domain>

Domain suffix for the FQDN (optional). Used together with C<hostname> to
set C</etc/hosts>. If C<hostname> is given without C<domain>, hostname is
still set but no hosts entry is written.

=item C<timezone>

Timezone string, e.g. C<Europe/Berlin>. Default: C<UTC>.

=item C<token>

Shared cluster secret used for node joining. Auto-generated if omitted.

=item C<tls_san>

Additional TLS Subject Alternative Names for the API server certificate.
Accepts a string (single SAN or comma-separated list) or an arrayref.
The first SAN is used as the server address when patching the kubeconfig
(see C<kubeconfig_file> below).

=item C<kubeconfig_file>

Local file path where the cluster kubeconfig is saved after the server is
running. Required for the NVIDIA device plugin step to work. Optional — if
omitted no local kubeconfig is saved and device plugin deployment is skipped
even when C<gpu =E<gt> 1>.

RKE2 and K3s write C<https://127.0.0.1> into the kubeconfig. The first
C<tls_san> entry (or C<kubeconfig_server> if provided) is substituted for
C<127.0.0.1> so the saved file connects to the real server address.

=item C<kubeconfig_server>

Explicit server address to use when patching the kubeconfig. Overrides the
C<tls_san>-based default.

=item C<node_labels>

Node labels to apply, as an arrayref of C<key=value> strings.

=item C<registries>

Private registry mirror configuration hashref, written to C<registries.yaml>.
See L<Rex::Rancher::Server/install_server> for the structure.

=item C<cilium>

Whether to configure Cilium CNI. Default: C<1>. Set to C<0> to keep the
distribution's built-in CNI (Canal for RKE2, Flannel for K3s).

=back

=head2 rancher_deploy_agent(%opts)

Full worker node deployment: prepare the node, optionally set up GPU
support, install the Kubernetes agent, and join the existing cluster.

The pipeline is shorter than L</rancher_deploy_server> — there is no
Cilium installation or kubeconfig retrieval. GPU support via
C<gpu =E<gt> 1> works identically to the server case.

Options: same as L</rancher_deploy_server> plus:

=over

=item C<server>

URL of the server to join. For RKE2: C<https://SERVER_IP:9345>. For K3s:
C<https://SERVER_IP:6443>. Required.

=item C<token>

Node join token. Obtain from the server with
L<Rex::Rancher::Server/get_token>. Required.

=item C<node_name>

Override the node name registered in Kubernetes (optional).

=back

=head1 SEE ALSO

L<Rex>, L<Rex::LibSSH>, L<Rex::GPU>, L<Rex::Rancher::K8s>,
L<Kubernetes::REST>, L<IO::K8s>

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
