# ABSTRACT: Rancher Kubernetes (RKE2/K3s) deployment automation for Rex

package Rex::Rancher;

use v5.14.4;
use warnings;

our $VERSION = '0.002';

use Rex::Rancher::Node;
use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::Cilium;
use Rex::Rancher::K8s;
use Rex::Logger;

use File::Basename qw(dirname);
use File::Path qw(make_path);

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  rancher_deploy_server
  rancher_deploy_agent
  rancher_scan_known_hosts
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

  my %cilium_opts = (
    distribution => $distribution,
    ( map { exists $opts{"cilium_$_"} ? ( $_ => $opts{"cilium_$_"} ) : () }
        qw( version cli_version helm_values ) ),
    ( map { exists $opts{$_} ? ( $_ => $opts{$_} ) : () }
        qw( gateway_api gateway_api_version gateway_api_channel k8s_service_host ) ),
  );
  # k3s: Cilium reaches the API at the control plane's address, which is the
  # first tls_san, the name the certificate is made for. No fallback to the
  # kubeconfig_server (this machine's view) or localhost (agents have no
  # 6443 there); install_cilium dies without one.
  if ($distribution eq 'k3s' && !exists $cilium_opts{k8s_service_host}) {
    my $first_san = _kubeconfig_server_addr(tls_san => $opts{tls_san});
    $cilium_opts{k8s_service_host} = $first_san if defined $first_san && length $first_san;
  }
  my $cilium = exists $opts{cilium} ? $opts{cilium} : 1;

  # Refuse bad or contradictory Cilium options before the node is touched,
  # not at step 7.
  if ($cilium) {
    Rex::Rancher::Cilium::_resolve_opts(%cilium_opts, kubeconfig => $kubeconfig_file);
  }
  else {
    my @set = (
      ( $opts{gateway_api} ? 'gateway_api' : () ),
      ( grep { defined $opts{$_} }
          qw( cilium_version cilium_cli_version cilium_helm_values k8s_service_host ) ),
    );
    die "cilium => 0 keeps the distribution's built-in CNI, but @set "
      . "configure Cilium: drop them or leave cilium on\n" if @set;
  }

  _check_connection();
  prepare_node(%opts);

  _gpu_setup_if_requested($distribution, %opts);

  install_server(_install_opts(%opts), _gateway_api_disable(%opts));

  # Fetch and save kubeconfig locally, then wait for the API from this machine.
  # install_server only waits for the kubeconfig file to appear on the remote;
  # actual API readiness is confirmed here via Rex::Rancher::K8s::wait_for_api.
  my $local_kc = _save_kubeconfig_locally($distribution, $kubeconfig_file, %opts);
  my $api_up = $local_kc && wait_for_api(kubeconfig => $local_kc);

  # A saved kubeconfig whose API never answered: everything after needs that
  # API (Helm release state, gateway_api, device plugin), so stop here rather
  # than fall back to the remote-only Cilium path and fail later on a
  # misleading error. The server itself is installed; a re-run picks up.
  if ($local_kc && !$api_up) {
    my $addr = _kubeconfig_server_addr(%opts) // '127.0.0.1';
    die "Kubernetes API at $addr did not answer through $local_kc within "
      . "wait_for_api's timeout; $distribution server is installed, Cilium "
      . "and later steps did not run. Check that this machine reaches "
      . "$addr:6443 (firewall, tls_san, kubeconfig_server), or omit "
      . "kubeconfig_file to install Cilium through the remote host only\n";
  }

  # Without a saved kubeconfig install_cilium keeps its remote-only path.
  # cilium => 0: install_server kept Canal/Flannel, nothing to install here.
  install_cilium(%cilium_opts, $api_up ? ( kubeconfig => $local_kc ) : ()) if $cilium;

  my %gpu_steps = _gpu_steps(%opts);
  if ($gpu_steps{device_plugin} && $local_kc) {
    deploy_nvidia_device_plugin(kubeconfig => $local_kc);
  }

  Rex::Logger::info("$distribution server deployment complete");
}


sub rancher_deploy_agent {
  my (%opts) = @_;
  my $distribution = $opts{distribution} // 'rke2';

  # install_agent needs both; refuse before prepare_node and gpu_setup
  # (driver install, possibly a reboot) have touched the host.
  die "server is required for rancher_deploy_agent\n" unless $opts{server};
  die "token is required for rancher_deploy_agent\n"  unless $opts{token};

  _check_connection();
  prepare_node(%opts);

  _gpu_setup_if_requested($distribution, %opts);

  install_agent(_install_opts(%opts));

  Rex::Logger::info("$distribution agent deployment complete");
}


sub rancher_scan_known_hosts {
  my ($host, %opts) = @_;

  $host = "$host" if ref $host;    # Rex server objects stringify to the host
  return unless defined $host && length $host;
  return if $host eq 'localhost' || $host eq '127.0.0.1' || $host eq '::1';

  unless (_have_local_command('ssh-keyscan')) {
    Rex::Logger::info(
      "ssh-keyscan not found locally — cannot pre-seed the host key for "
        . "$host; a verified connect will fail if the key is unknown", "warn");
    return;
  }

  my $known_hosts = $opts{known_hosts};
  unless (defined $known_hosts && length $known_hosts) {
    unless ($ENV{HOME}) {
      Rex::Logger::info(
        "Cannot scan host key for $host: \$HOME is unset and no known_hosts "
          . "path was given", "warn");
      return;
    }
    $known_hosts = "$ENV{HOME}/.ssh/known_hosts";
  }

  # Idempotent: if the key is already trusted, leave known_hosts untouched —
  # never disturb a key the operator has already pinned.
  return if -f $known_hosts && _known_host_present($host, $known_hosts);

  my $keys = _run_local_capture('ssh-keyscan', $host) // '';
  my @key_lines = grep { /\S/ && !/^\s*#/ } split /\n/, $keys;
  unless (@key_lines) {
    Rex::Logger::info(
      "ssh-keyscan returned no host key for $host (host unreachable?) — "
        . "known_hosts left unchanged", "warn");
    return;
  }

  my $dir = dirname($known_hosts);
  make_path($dir, { mode => 0700 }) if length $dir && !-d $dir;

  open(my $fh, '>>', $known_hosts)
    or do {
      Rex::Logger::info(
        "Cannot append to $known_hosts: $! — host key for $host not saved",
        "warn");
      return;
    };
  print $fh "$_\n" for @key_lines;
  close $fh;

  Rex::Logger::info("Scanned host key for $host into $known_hosts");
  return 1;
}

sub _known_host_present {
  my ($host, $known_hosts) = @_;
  return 0 unless _have_local_command('ssh-keygen');
  # ssh-keygen -F exits 0 when a matching entry exists (handles hashed hosts),
  # 1 otherwise. Its stdout is captured so the found line is not echoed.
  _run_local_capture('ssh-keygen', '-F', $host, '-f', $known_hosts);
  return ($? >> 8) == 0 ? 1 : 0;
}

sub _have_local_command {
  my ($name) = @_;
  for my $dir (split /:/, ($ENV{PATH} // '')) {
    return 1 if length $dir && -x "$dir/$name";
  }
  return 0;
}

sub _run_local_capture {
  my (@cmd) = @_;
  my $pid = open(my $out, '-|', @cmd) or return;
  local $/;
  my $content = <$out>;
  close $out;    # sets $? to the child exit status
  return defined $content ? $content : '';
}

# Which GPU steps run, from the options alone. Without gpu nothing does; with
# gpu each step runs unless its own switch turns it off. runtime_path: the
# rke2 unit PATH for a toolkit the host brought, needed only without gpu_setup
# (Rex::GPU's containerd drop-in names the runtime by absolute path).
sub _gpu_steps {
  my (%opts) = @_;
  return ( setup => 0, device_plugin => 0, runtime_path => 0 ) unless $opts{gpu};
  my $setup = ( $opts{gpu_setup} // 1 ) ? 1 : 0;
  return (
    setup         => $setup,
    device_plugin => ( $opts{gpu_device_plugin} // 1 ) ? 1 : 0,
    runtime_path  => $setup ? 0 : 1,
  );
}

# The options install_server/install_agent get: the caller's, plus
# nvidia_runtime_path from the GPU switches unless the caller set it.
sub _install_opts {
  my (%opts) = @_;
  my %steps = _gpu_steps(%opts);
  return ( %opts, nvidia_runtime_path => $opts{nvidia_runtime_path} // $steps{runtime_path} );
}

# gateway_api on rke2 (validated earlier): RKE2 v1.37+'s own Gateway API
# CRD chart must stay off, or it overwrites what install_cilium applies. The
# default disable list gains it; a caller's own list is theirs to keep.
sub _gateway_api_disable {
  my (%opts) = @_;
  return unless $opts{gateway_api} && ($opts{distribution} // 'rke2') eq 'rke2';

  my $chart = 'rke2-gateway-api-crd';
  my $disable = $opts{disable};
  return ( disable => [ @{ Rex::Rancher::Server::_paths('rke2')->{disable} }, $chart ] )
    unless defined $disable;

  my @given = ref $disable eq 'ARRAY' ? @$disable : split(/,/, $disable);
  Rex::Logger::info("gateway_api with a disable list lacking $chart: on RKE2 "
    . "v1.37+ that chart overwrites the Gateway API CRDs Cilium relies on", 'warn')
    unless grep { $_ eq $chart } @given;
  return;
}

sub _gpu_setup_if_requested {
  my ($distribution, %opts) = @_;

  my %steps = _gpu_steps(%opts);
  if ($opts{gpu} && !$steps{setup}) {
    Rex::Logger::info("gpu_setup => 0: Rex::GPU not used, driver, toolkit and containerd config are left to the host or the GPU Operator");
    Rex::Logger::info("reboot is ignored with gpu_setup => 0", "warn") if $opts{reboot};
  }
  return unless $steps{setup};

  my $loaded = eval { require Rex::GPU; Rex::GPU->import(); 1 };
  unless ($loaded) {
    die "gpu => 1 requested but Rex::GPU is not installed. Install the Rex-GPU distribution, or pass gpu_setup => 0 if the GPU Operator or the host provides the driver.\n";
  }

  Rex::GPU::gpu_setup(
    containerd_config => $distribution,
    reboot            => ($opts{reboot} // 0),
  );
}

sub _save_kubeconfig_locally {
  my ($distribution, $output_file, %opts) = @_;

  return unless $output_file;

  # kubeconfig_file was asked for: without it wait_for_api, the Helm-aware
  # Cilium path, gateway_api and the device plugin cannot run, so a failed
  # fetch or write stops the deploy instead of degrading to the remote-only
  # path. The server is installed by now; a re-run reuses its token.
  my $stopped = "; $distribution server is installed, Cilium and later steps "
    . "did not run. Fix the cause and re-run, or omit kubeconfig_file to "
    . "install Cilium through the remote host only\n";

  my $content = eval { get_kubeconfig($distribution) };
  unless ($content) {
    my $err = $@ ? $@ =~ s/\s+\z//r : 'empty file';
    die "Could not fetch the kubeconfig from the $distribution server "
      . "($err)$stopped";
  }

  # RKE2/K3s writes 127.0.0.1 in the kubeconfig; patch to the real address
  my $server_addr = _kubeconfig_server_addr(%opts);
  my %loopback = map { $_ => 1 } qw(127.0.0.1 localhost ::1);

  if (!defined $server_addr || !length $server_addr) {
    # No tls_san / kubeconfig_server given: nothing to patch to, so the saved
    # file keeps pointing at 127.0.0.1 and cannot reach the cluster remotely.
    # Still save it (a local-only operator may want it) but make it loud.
    Rex::Logger::info(
      "Kubeconfig saved to $output_file but no server address could be "
        . "derived — it still points at https://127.0.0.1 and will not reach "
        . "the cluster from this machine; pass tls_san or kubeconfig_server",
      "warn");
  }
  else {
    if ($loopback{lc $server_addr}) {
      # A loopback address patches 127.0.0.1 to itself (or another loopback):
      # still unreachable from the operator's machine.
      Rex::Logger::info(
        "Kubeconfig server address '$server_addr' is a loopback address — the "
          . "kubeconfig saved to $output_file will still point at the loopback "
          . "interface and will not reach the cluster from this machine; pass "
          . "a routable tls_san or kubeconfig_server", "warn");
    }
    $content =~ s{https://127\.0\.0\.1:(\d+)}{https://$server_addr:$1}g;
  }

  open(my $fh, '>', $output_file)
    or die "Could not write the kubeconfig to $output_file: $!$stopped";
  print $fh $content;
  close $fh
    or die "Could not write the kubeconfig to $output_file: $!$stopped";

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

version 0.002

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
separately. Rex::Rancher works identically for non-GPU nodes. Clusters that
hand the GPU to the NVIDIA GPU Operator pass C<gpu_setup =E<gt> 0> and/or
C<gpu_device_plugin =E<gt> 0> and need no L<Rex::GPU>.

When deploying a GPU server node, the full pipeline runs automatically:

=over

=item 1. B<Node preparation> — base packages (on Debian/Ubuntu after stopping
the automatic apt services), hostname, timezone, locale, NTP, swap off,
kernel modules (br_netfilter, overlay), sysctl for Kubernetes networking.

=item 2. B<GPU setup> (C<gpu =E<gt> 1>, unless C<gpu_setup =E<gt> 0>) — NVIDIA driver via DKMS, optional
reboot, Container Toolkit, CDI specs, containerd runtime config. Handled by
L<Rex::GPU>.

=item 3. B<Cluster bring-up> — write config (with C<cilium>, the
distribution's own CNI switched off), run RKE2 or K3s install script,
wait for kubeconfig file on the remote host, then, with C<kubeconfig_file>,
fetch and save it locally and wait for API server readiness via
L<Kubernetes::REST>.

=item 4. B<Cilium CNI> (skipped with C<cilium =E<gt> 0>, which leaves the
distribution's own CNI in place) — Cilium CLI installed on the remote host,
Cilium installed, upgraded or left alone with distribution-appropriate Helm
values (kube-proxy replacement on both).

=item 5. B<NVIDIA device plugin> (C<gpu =E<gt> 1> + C<kubeconfig_file>, unless
C<gpu_device_plugin =E<gt> 0>) — DaemonSet
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

=head2 GPU hardware support

With C<gpu =E<gt> 1> (and C<gpu_setup> not switched off), driver choice and
hardware checks are made by L<Rex::GPU>'s C<gpu_setup>; Rex::Rancher passes only the distribution and
C<reboot>. Newer L<Rex::GPU> versions behave as follows:

=over

=item * B<Blackwell> (RTX 50xx, RTX PRO, B200/GB200, B300): the open kernel
driver on Ubuntu; on Debian 12 and 13 the driver comes from NVIDIA's CUDA
repository. Any other release or architecture makes C<gpu_setup> die.

=item * B<Maxwell, Pascal, Volta> (e.g. P100, V100, GTX 9xx/10xx, GT 1030,
GeForce MX): pinned to the proprietary 580 driver branch.

=item * B<Which GPUs get a driver> is decided by generation, not by name:
every Maxwell-or-newer GPU counts, consumer and laptop cards (GeForce MX,
GT 1030, GTX 9xx, laptop RTX) included. Earlier L<Rex::GPU> versions skipped
these, so a re-deploy with C<gpu =E<gt> 1> on such a node now installs the
driver and, with C<reboot>, reboots it; afterwards the node reports
C<nvidia.com/gpu>.

=item * B<Kepler and older> (e.g. GT 710, GTX 7xx, Tesla K80/K40/K20): skipped
with a warning, no driver is installed, and a newer GPU on the same host is
still set up. A node whose only NVIDIA GPUs are Kepler no longer dies: the
deploy carries on without a GPU, and step 6 deploys the device plugin, waits
about two minutes for C<nvidia.com/gpu> and ends with a warning — pass
C<gpu_device_plugin =E<gt> 0> (or leave out C<gpu>) for such a node.

=item * B<VMs with a passed-through GPU> next to an emulated console are
detected as GPU hosts and get the full GPU pipeline, including the driver
reboot — set C<reboot> accordingly.

=item * B<NVIDIA vGPU guests> (e.g. Azure NVadsA10 v5, AWS G6f; told apart
from a passed-through card by PCI subsystem ID) need NVIDIA's licensed vGPU
guest driver, which L<Rex::GPU> does not install. If it already works
(C<nvidia-smi -L> lists the GPU and C<libcuda.so.1> is in the linker cache)
the deploy goes on as usual; otherwise C<gpu_setup> dies naming the vGPU
type, also when a non-vGPU GPU sits on the same host.

=item * B<HGX B200/B300>: the driver is installed as for any Blackwell, then
a warning notes that CUDA needs NVIDIA Fabric Manager, the NVLink Subnet
Manager (C<nvlsm>), OFED/MOFED and kernel 5.17 or newer, none of which
L<Rex::GPU> sets up (it only checks whether Fabric Manager is running).
B<GB200/GB300> NVL72 trays get an info line that multi-node NVLink needs
C<nvidia-imex>. Log output only; the deploy is unchanged.

=item * B<Several compute GPUs>: the driver must satisfy all of them (Ada +
V100 gives 580, Ada + B200 gives the open driver). If no driver fits (V100 +
B200) and none is already installed, or no package source serves the
required driver for the OS (e.g. Debian 14 with Blackwell or V100),
C<gpu_setup> dies.

=back

Such a die comes before any driver package is installed. At most
C<pciutils> has been installed for detection (when C<lspci> was missing),
unless the missing package source only shows once the package index is
refreshed (e.g. Ubuntu, where no fitting driver package is found): then the
package sources have already been prepared (C<apt-get update>, repositories
added or enabled). The die is not caught: L</rancher_deploy_server> and
L</rancher_deploy_agent> abort with it. It does, however, come after
L<Rex::Rancher::Node/prepare_node> has already run, so base packages,
hostname, timezone, locale, swap, kernel modules and sysctl are already
changed; no Kubernetes distribution has been
installed yet. See L<Rex::GPU> for the details of detection and driver
selection.

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

=item 1. C<prepare_node> — base packages, hostname, timezone, locale, NTP, swap off, kernel modules, sysctl

=item 2. C<gpu_setup> (only with C<gpu =E<gt> 1>, unless C<gpu_setup =E<gt> 0>) — driver + toolkit + CDI + containerd config

=item 3. C<install_server> — write config, run installer, wait for the service to be active, then for the kubeconfig file

=item 4. Fetch kubeconfig locally, patch C<127.0.0.1> to the real server address,
save to C<kubeconfig_file>, wait for API with L<Rex::Rancher::K8s/wait_for_api>
(skipped without C<kubeconfig_file>)

=item 5. C<install_cilium> (skipped with C<cilium =E<gt> 0>) — install Cilium CLI on remote, then install,
upgrade or leave Cilium alone according to its Helm release (read through the
saved kubeconfig once the API answered; without one, plain C<cilium install>)

=item 6. C<deploy_nvidia_device_plugin> (only with C<gpu =E<gt> 1> and C<kubeconfig_file>, unless C<gpu_device_plugin =E<gt> 0>)

=back

If the API does not answer through the saved kubeconfig within
L<Rex::Rancher::K8s/wait_for_api>'s five minutes, the deploy dies naming the
address it tried: the distribution is installed and running, but Cilium and
the device plugin are not, and the node stays C<NotReady> until a re-run
(which reuses the token and picks up from there). The usual causes are the
address (C<tls_san>, C<kubeconfig_server>), a firewall between this machine
and port 6443, or a SAN missing from the certificate. Without
C<kubeconfig_file> nothing is awaited and Cilium is installed through the
remote host alone.

Options:

=over

=item C<distribution>

Kubernetes distribution to install. C<rke2> (default) or C<k3s>.

=item C<gpu>

If true, detect GPUs and run the full GPU setup pipeline via L<Rex::GPU>
before installing the Kubernetes distribution, and deploy the NVIDIA device
plugin once the API answers. Requires L<Rex::GPU> to be installed unless
C<gpu_setup =E<gt> 0>. Default: C<0>; without it no GPU step runs and
C<gpu_setup>/C<gpu_device_plugin> are ignored. Driver selection depends on the
GPU generation, and some hardware/OS combinations make the deploy die instead
— see L</GPU hardware support>.

=item C<gpu_setup>

With C<gpu =E<gt> 1>: whether step 2 runs L<Rex::GPU>'s C<gpu_setup> (driver,
container toolkit, CDI, containerd config). Default: C<1>. Pass C<0> when the
NVIDIA GPU Operator (C<driver.enabled>, C<toolkit.enabled>) or the host image
provides these; L<Rex::GPU> is then not loaded and need not be installed.
On rke2, C<gpu_setup =E<gt> 0> also turns on C<nvidia_runtime_path>.

=item C<nvidia_runtime_path>

Passed to L<Rex::Rancher::Server/install_server> (and
L<Rex::Rancher::Agent/install_agent>): write a C<PATH> to
C</etc/default/rke2-server> (C<rke2-agent>) before the first start, so rke2
finds a host-installed C<nvidia-container-runtime> (DGX OS, a preinstalled
toolkit in C</usr/bin>); skipped when there is none on the host. Default: on
for C<gpu =E<gt> 1, gpu_setup =E<gt> 0>, off otherwise. No effect on k3s.

=item C<gpu_device_plugin>

With C<gpu =E<gt> 1>: whether step 6 deploys the NVIDIA device plugin
DaemonSet. Default: C<1>. Pass C<0> when the GPU Operator runs its own device
plugin (C<devicePlugin.enabled>) — two plugins would both advertise
C<nvidia.com/gpu>. With C<gpu_setup =E<gt> 0> and this left on, the driver and
the C<nvidia> runtime must already be on the host, or the plugin finds no GPU
and the deploy ends with a warning.

=item C<reboot>

If true, reboot the host after GPU driver installation and wait for it to
come back before proceeding. Only meaningful when L<Rex::GPU>'s C<gpu_setup>
runs (C<gpu =E<gt> 1> without C<gpu_setup =E<gt> 0>); otherwise it is ignored
with a warning. Required on first deploy when C<nouveau> was previously
loaded. Default: C<0>.

=item C<hostname>

Short hostname to set on the node (optional). If omitted, the existing
hostname is left unchanged.

=item C<domain>

Domain suffix for the FQDN (optional). Used together with C<hostname> to
set C</etc/hosts>. If C<hostname> is given without C<domain>, hostname is
still set but no hosts entry is written.

=item C<timezone>

Timezone string, e.g. C<Europe/Berlin>. Default: C<UTC>.

=item C<locale>

System locale, e.g. C<de_DE.UTF-8>. Default: C<en_US.UTF-8>. See
L<Rex::Rancher::Node/prepare_node>.

=item C<ntp>

Install and start C<chrony>. Default: C<1>; pass C<0> to leave time sync to
the host (e.g. a VM with hypervisor time sync).

=item C<server>

URL of an existing server to join as an additional control plane node (HA),
passed to L<Rex::Rancher::Server/install_server>: C<https://SERVER:9345> for
RKE2, C<https://SERVER:6443> for K3s. Omit it for the first server.

=item C<token>

Shared cluster secret used for node joining. If omitted, the token of an
already-installed server on the host is reused (a re-run never rotates it);
only a fresh server gets a generated one. See
L<Rex::Rancher::Server/install_server>.

=item C<tls_san>

Additional TLS Subject Alternative Names for the API server certificate.
Accepts a string (single SAN or comma-separated list) or an arrayref.
The first SAN is used as the server address when patching the kubeconfig
(see C<kubeconfig_file> below), and on K3s with Cilium as the address Cilium
reaches the API server at (see C<k8s_service_host>), so it must be reachable
from every node.

=item C<kubeconfig_file>

Local file path where the cluster kubeconfig is saved after the server is
running. Required for the NVIDIA device plugin step to work. Optional — if
omitted no local kubeconfig is saved and device plugin deployment is skipped
even when C<gpu =E<gt> 1>.

RKE2 and K3s write C<https://127.0.0.1> into the kubeconfig. The first
C<tls_san> entry (or C<kubeconfig_server> if provided) is substituted for
C<127.0.0.1> so the saved file connects to the real server address. If no
address can be derived (neither C<tls_san> nor C<kubeconfig_server> given), or
the derived address is itself loopback (C<127.0.0.1>, C<localhost>, C<::1>),
the file is still saved but a warning is logged: it will keep pointing at
C<https://127.0.0.1> and cannot reach the cluster from the operator's machine.

If the kubeconfig cannot be fetched from the host or written to
C<kubeconfig_file>, the deploy dies naming the cause, like the API timeout
above: the server is installed, Cilium and the device plugin are not, and a
re-run picks up from there.

=item C<kubeconfig_server>

Explicit server address to use when patching the kubeconfig. Overrides the
C<tls_san>-based default, so the kubeconfig can point at an address that is
not the first C<tls_san> entry (e.g. the node's advertised host while
C<tls_san> lists every control-plane address). Only the kubeconfig is
affected; the address must still be a name in the API server certificate
(the node's own IPs and hostname, or a C<tls_san> entry).

=item C<version>

Pinned distribution version (C<INSTALL_RKE2_VERSION> / C<INSTALL_K3S_VERSION>).
Default: latest stable. When given, the installed version is verified and a
mismatch dies. See L<Rex::Rancher::Server/install_server>.

=item C<install_method>

C<script> (default, C<curl | sh>) or C<artifact> (checksum-verified release
artifact for the node's architecture, downloaded on the host; requires
C<version>). See L<Rex::Rancher::Server/install_server>.

=item C<node_name>

Kubernetes node name (C<node-name> in C<config.yaml>). Default: the hostname.

=item C<disable>

Packaged components to switch off (C<disable> in C<config.yaml>). Default:
C<rke2-ingress-nginx>, C<rke2-traefik> and C<rke2-traefik-crd> on rke2,
C<traefik> and C<servicelb> on k3s; a given list replaces the default. With
C<gateway_api> the rke2 default also holds C<rke2-gateway-api-crd> (see
C<gateway_api> below). See L<Rex::Rancher::Server/install_server>.

=item C<node_labels>

Node labels to apply, as an arrayref of C<key=value> strings.

=item C<registries>

Private registry mirror configuration hashref, written to C<registries.yaml>.
See L<Rex::Rancher::Server/install_server> for the structure.

=item C<cilium>

Whether Cilium is the cluster's CNI. Default: C<1>: the distribution's own
CNI and kube-proxy are switched off in C<config.yaml> (RKE2: C<cni: none>
and C<disable-kube-proxy: true>; K3s: C<flannel-backend: none>,
C<disable-network-policy: true>, C<disable-kube-proxy: true> and
C<cluster-cidr: 10.42.0.0/16>) and Cilium is installed in step 5 with
kube-proxy replacement. K3s carries the configuration kubernetes-ocp
verified live, but has not been run live through Rex::Rancher, which
defaults to an older Cilium (see L<Rex::Rancher::Cilium>). Set to
C<0> and Rex::Rancher does nothing CNI-related: the distribution's built-in
CNI comes up (Canal for RKE2, Flannel for K3s) and the pipeline skips
L<Rex::Rancher::Cilium/install_cilium> entirely. Passing
C<gateway_api>, C<cilium_version>, C<cilium_cli_version>,
C<cilium_helm_values> or C<k8s_service_host> together with
C<cilium =E<gt> 0> dies before the node is touched.

=item C<cilium_version>, C<cilium_cli_version>, C<cilium_helm_values>

Passed to L<Rex::Rancher::Cilium/install_cilium> as C<version>,
C<cli_version> and C<helm_values>.

=item C<k8s_service_host>

K3s only: the control plane address Cilium reaches the API server at from
every node, passed to L<Rex::Rancher::Cilium/install_cilium>. Default: the
first C<tls_san>. Without either, a K3s deploy with Cilium dies before the
node is touched: K3s agents serve the API on C<127.0.0.1:6444>, so no
localhost address works on every node. Passing it on RKE2 dies, also before
the node is touched.

=item C<gateway_api>, C<gateway_api_version>, C<gateway_api_channel>

Passed to L<Rex::Rancher::Cilium/install_cilium> unchanged. C<gateway_api>
needs C<kubeconfig_file>; invalid Cilium options die before the node is
touched.

With C<gateway_api>, Cilium's CRDs have to be the only ones: RKE2 v1.37+
would otherwise install its own C<rke2-gateway-api-crd> chart over them
(older RKE2 ignores the name). Without a C<disable> of yours it is added to
the default list; a C<disable> of yours that lacks it is used as given, with
a warning. On a running cluster the change to C<config.yaml> takes effect
only when C<rke2-server> restarts; until then
L<Rex::Rancher::Cilium/install_cilium> dies while RKE2's release exists.

=back

=head2 rancher_deploy_agent(%opts)

Full worker node deployment: prepare the node, optionally set up GPU
support, install the Kubernetes agent, and join the existing cluster.

The pipeline is shorter than L</rancher_deploy_server> — there is no
Cilium installation or kubeconfig retrieval. GPU host setup via
C<gpu =E<gt> 1> (and C<gpu_setup>, C<reboot>) works identically to the server
case; there is no device plugin step, so C<gpu_device_plugin> has no effect
here.

Options:

=over

=item C<server>

URL of the server to join. For RKE2: C<https://SERVER_IP:9345>. For K3s:
C<https://SERVER_IP:6443>. Required.

=item C<token>

Node join token. Obtain from the server with
L<Rex::Rancher::Server/get_token>. Required.

=item C<node_name>

Override the node name registered in Kubernetes (optional).

=item C<distribution>, C<version>, C<install_method>, C<node_labels>, C<registries>, C<nvidia_runtime_path>

As for L</rancher_deploy_server>; passed to
L<Rex::Rancher::Agent/install_agent>.

=item C<hostname>, C<domain>, C<timezone>, C<locale>, C<ntp>

As for L</rancher_deploy_server>; passed to
L<Rex::Rancher::Node/prepare_node>.

=item C<gpu>, C<gpu_setup>, C<reboot>

As for L</rancher_deploy_server> (step 2).

=back

A missing C<server> or C<token> dies before the host is touched. As on the
server, an SFTP-less host needs the C<LibSSH> connection backend; without it
the deploy dies before the first step with a hint to C<Rex::LibSSH>.

The server-only options have no effect on an agent and are ignored:
C<tls_san>, C<disable>, C<kubeconfig_file>,
C<kubeconfig_server>, C<cilium>, C<cilium_version>, C<cilium_cli_version>,
C<cilium_helm_values>, C<gateway_api>, C<gateway_api_version>,
C<gateway_api_channel>, C<k8s_service_host> and C<gpu_device_plugin>. Whether
a K3s agent runs Flannel and kube-proxy or leaves both to Cilium follows the
server's C<config.yaml>.

=head2 rancher_scan_known_hosts($host, %opts)

Pre-seed the local C<known_hosts> with C<$host>'s SSH host key by running
C<ssh-keyscan> B<on the machine executing Rex> (not on the target). Returns
true if a key was added, false/undef otherwise.

This is a I<pre-connect> helper: L<Rex::LibSSH> E<gt>= 0.004 verifies the
server host key against C<known_hosts> (a CWE-322 fix; earlier versions never
checked). A freshly-installed host — the Hetzner dedicated servers this
distribution targets — has no C<known_hosts> entry, so the very first verified
connect dies with C<host key is not in known_hosts and strict_hostkeycheck is
on>. Scanning the key in beforehand fixes that while B<keeping> host-key
verification on, which is why this is preferred over disabling the check.

Because Rex opens the connection before the task body runs, call this from a
C<before> hook so it executes ahead of C<connect> (see the C<before 'ALL'>
block in F<eg/hetzner-gpu.Rexfile>). It shells out locally and never uses
Rex's C<run>, since there is no connection yet:

  before 'ALL' => sub {
    my ($server) = @_;
    rancher_scan_known_hosts($server);
  };

It is idempotent (an already-trusted host is left untouched) and degrades to a
warning — never a hard failure — when C<ssh-keyscan> is absent or the host is
unreachable; the subsequent verified connect then surfaces the real error.

Options:

=over

=item C<known_hosts>

Path to the C<known_hosts> file to update. Defaults to
C<$HOME/.ssh/known_hosts>.

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
