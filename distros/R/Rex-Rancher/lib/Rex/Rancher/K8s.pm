# ABSTRACT: Kubernetes API operations for Rex::Rancher (device plugin, readiness)

package Rex::Rancher::K8s;
our $VERSION = '0.001';
use v5.14.4;
use warnings;

use Kubernetes::REST::Kubeconfig;
use Rex::Logger;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  deploy_nvidia_device_plugin
  wait_for_api
  untaint_node
);

use constant DEVICE_PLUGIN_VERSION => 'v0.17.0';


sub wait_for_api {
  my (%opts) = @_;
  my $kubeconfig = $opts{kubeconfig} or die "kubeconfig required\n";

  Rex::Logger::info("Waiting for Kubernetes API server...");

  for my $i (1..60) {
    my $up = eval {
      my $api = _api($kubeconfig);
      $api->list('Node');
      1;
    };
    if ($up) {
      Rex::Logger::info("  API server is up");
      return 1;
    }
    Rex::Logger::info("  Not responding yet, waiting... ($i/60)");
    sleep 5;
  }

  Rex::Logger::info("Kubernetes API server did not respond in time", "warn");
  return 0;
}


sub deploy_nvidia_device_plugin {
  my (%opts) = @_;
  my $kubeconfig = $opts{kubeconfig} or die "kubeconfig required\n";
  my $version    = $opts{version} // DEVICE_PLUGIN_VERSION;

  Rex::Logger::info("Deploying NVIDIA device plugin $version...");

  my $api = _api($kubeconfig);

  my $ds = $api->new_object(DaemonSet =>
    metadata => {
      name      => 'nvidia-device-plugin-daemonset',
      namespace => 'kube-system',
    },
    spec => {
      selector => {
        matchLabels => { name => 'nvidia-device-plugin-ds' },
      },
      updateStrategy => { type => 'RollingUpdate' },
      template => {
        metadata => {
          labels => { name => 'nvidia-device-plugin-ds' },
        },
        spec => {
          runtimeClassName  => 'nvidia',
          priorityClassName => 'system-node-critical',
          tolerations => [{
            key      => 'nvidia.com/gpu',
            operator => 'Exists',
            effect   => 'NoSchedule',
          }],
          containers => [{
            name  => 'nvidia-device-plugin-ctr',
            image => "nvcr.io/nvidia/k8s-device-plugin:$version",
            env   => [{
              name  => 'FAIL_ON_INIT_ERROR',
              value => 'false',
            }],
            securityContext => {
              allowPrivilegeEscalation => \0,
              capabilities            => { drop => ['ALL'] },
            },
            volumeMounts => [{
              name      => 'device-plugin',
              mountPath => '/var/lib/kubelet/device-plugins',
            }],
          }],
          volumes => [{
            name     => 'device-plugin',
            hostPath => { path => '/var/lib/kubelet/device-plugins' },
          }],
        },
      },
    },
  );

  eval { $api->create($ds) };
  if ($@) {
    if ($@ =~ /already exist/i) {
      Rex::Logger::info("  DaemonSet already exists, updating...");
      my $existing = $api->get('DaemonSet', 'nvidia-device-plugin-daemonset',
        namespace => 'kube-system');
      $ds->metadata->resourceVersion($existing->metadata->resourceVersion);
      $api->update($ds);
    }
    else {
      die $@;
    }
  }

  Rex::Logger::info("  DaemonSet applied, waiting for GPU resources...");
  _wait_for_gpu_resource($api);

  Rex::Logger::info("NVIDIA device plugin ready");
}


sub untaint_node {
  my (%opts) = @_;
  my $kubeconfig = $opts{kubeconfig} or die "kubeconfig required\n";

  Rex::Logger::info("Removing control-plane taints (single-node)...");

  my $api   = _api($kubeconfig);
  my $nodes = $api->list('Node');

  for my $node (@{ $nodes->items }) {
    my $name   = $node->metadata->name;
    my @taints = @{ $node->spec->taints // [] };
    my @keep   = grep {
      ($_->{key} // '') !~ /^node-role\.kubernetes\.io\/(control-plane|master)$/
    } @taints;

    next if @keep == @taints;  # nothing to remove

    my $fresh = $api->get('Node', $name);
    $fresh->spec->taints(\@keep);
    $api->update($fresh);
    Rex::Logger::info("  Untainted: $name");
  }
}

# ============================================================
#  Internal helpers
# ============================================================

sub _api {
  my ($kubeconfig) = @_;
  return Kubernetes::REST::Kubeconfig->new(
    kubeconfig_path => $kubeconfig,
  )->api;
}

sub _wait_for_gpu_resource {
  my ($api) = @_;

  for my $i (1..24) {
    my $found = eval {
      my $nodes = $api->list('Node');
      for my $node (@{ $nodes->items }) {
        my $cap = $node->status->capacity;
        if ($cap && $cap->{'nvidia.com/gpu'} && $cap->{'nvidia.com/gpu'} > 0) {
          Rex::Logger::info("  [ok] nvidia.com/gpu: "
            . $cap->{'nvidia.com/gpu'} . " on "
            . $node->metadata->name);
          return 1;  # returns 1 as value of the eval block
        }
      }
      0;
    };
    return 1 if $found;  # exit the sub once GPU capacity is confirmed
    Rex::Logger::info("  No GPU capacity yet ($i/24), waiting...");
    sleep 5;
  }

  Rex::Logger::info("  nvidia.com/gpu resource did not appear — check device plugin", "warn");
  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::K8s - Kubernetes API operations for Rex::Rancher (device plugin, readiness)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Rex::Rancher::K8s;

  # Wait for API to become available after cluster installation
  wait_for_api(kubeconfig => "$ENV{HOME}/.kube/mycluster.yaml");

  # Deploy NVIDIA device plugin and wait for gpu resource to appear
  deploy_nvidia_device_plugin(
    kubeconfig => "$ENV{HOME}/.kube/mycluster.yaml",
    version    => 'v0.17.0',
  );

  # Remove control-plane taints on a single-node cluster
  untaint_node(kubeconfig => "$ENV{HOME}/.kube/single.yaml");

=head1 DESCRIPTION

L<Rex::Rancher::K8s> provides Kubernetes API operations for L<Rex::Rancher>
using L<Kubernetes::REST> and L<IO::K8s>. All three public functions run
entirely on the B<local machine> against the cluster's HTTP API — no
C<kubectl> binary is required anywhere, and no SSH connection to the cluster
nodes is needed for these operations.

The module is used internally by L<Rex::Rancher/rancher_deploy_server> to:

=over

=item 1. Wait for the API server to respond after C<install_server> returns

=item 2. Deploy the NVIDIA device plugin when C<gpu =E<gt> 1>

=back

It can also be used standalone for post-deploy operations such as removing
control-plane taints on single-node clusters.

=head2 No kubectl required

All Kubernetes API calls are made via L<Kubernetes::REST>, which implements
the Kubernetes REST API client in pure Perl using L<IO::K8s> for object
serialization. The kubeconfig file is parsed by
C<Kubernetes::REST::Kubeconfig> to extract the cluster address and
credentials.

=head2 wait_for_api(%opts)

Wait for the Kubernetes API server to become reachable by polling
C<list(Node)> via L<Kubernetes::REST>. Runs from the local machine — no
SSH connection to the cluster is needed.

Polls up to 60 times with a 5-second delay between attempts (5-minute
total timeout). Returns C<1> as soon as the API responds, or C<0> if it
does not respond within the timeout.

Required options:

=over

=item C<kubeconfig>

Absolute path to the kubeconfig file saved locally. This file must have the
real server address (not C<127.0.0.1>) — L<Rex::Rancher/rancher_deploy_server>
patches the address automatically.

=back

  wait_for_api(kubeconfig => "$ENV{HOME}/.kube/mycluster.yaml");

=head2 deploy_nvidia_device_plugin(%opts)

Deploy the NVIDIA Kubernetes device plugin DaemonSet to C<kube-system> and
wait for C<nvidia.com/gpu> capacity to appear on at least one node.

All operations run locally via L<Kubernetes::REST> — no C<kubectl> or SSH
to the cluster is needed.

The DaemonSet is created with:

=over

=item * C<runtimeClassName: nvidia> — uses the NVIDIA container runtime
(registered by L<Rex::GPU::NVIDIA/configure_containerd>) to enumerate devices.

=item * C<priorityClassName: system-node-critical> — ensures the plugin
pod is scheduled even under resource pressure.

=item * A C<nvidia.com/gpu:NoSchedule> toleration — allows the pod to run
on nodes that still have the GPU taint.

=item * C<FAIL_ON_INIT_ERROR=false> — the plugin starts even if CDI or
driver initialisation fails, reporting partial GPU availability rather
than crash-looping.

=back

If the DaemonSet already exists it is updated (C<resourceVersion> is
fetched from the cluster before the update to satisfy the optimistic
concurrency requirement).

After applying, polls up to 24 times (2-minute timeout) for
C<nvidia.com/gpu> capacity to appear in any node's C<status.capacity>.

Required options:

=over

=item C<kubeconfig>

Local path to the cluster kubeconfig.

=back

Optional options:

=over

=item C<version>

NVIDIA device plugin image tag. Default: C<v0.17.0>.

=back

  deploy_nvidia_device_plugin(kubeconfig => "$ENV{HOME}/.kube/mycluster.yaml");

=head2 untaint_node(%opts)

Remove C<node-role.kubernetes.io/control-plane:NoSchedule> and
C<node-role.kubernetes.io/master:NoSchedule> taints from all nodes in the
cluster.

Kubernetes adds these taints to control-plane nodes to prevent general
workloads from being scheduled there. On single-node clusters (where the
control plane is also the only worker) these taints must be removed so that
pods can run.

Each node is fetched fresh before patching (to get the current
C<resourceVersion> for optimistic concurrency), and only patched if it
actually has one of the taints. Nodes that are already untainted are
skipped silently.

All operations run locally via L<Kubernetes::REST>.

Required options:

=over

=item C<kubeconfig>

Local path to the cluster kubeconfig.

=back

  untaint_node(kubeconfig => "$ENV{HOME}/.kube/single-node.yaml");

=head1 SEE ALSO

L<Rex::Rancher>, L<Rex::GPU>, L<Kubernetes::REST>, L<IO::K8s>

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
