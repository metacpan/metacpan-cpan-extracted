# Hetzner bare-metal GPU server → single-node RKE2 cluster
#
# Usage:
#   rex -f eg/hetzner-gpu-rke2.Rexfile -H <IP> deploy
#   rex -f eg/hetzner-gpu-rke2.Rexfile -H <IP> status
#   rex -f eg/hetzner-gpu-rke2.Rexfile -H <IP> untaint
#   rex -f eg/hetzner-gpu-rke2.Rexfile -H <IP> get_token
#
# Prerequisites:
#   - Fresh Debian/Ubuntu/openSUSE on Hetzner dedicated server with NVIDIA GPU
#   - SSH root access (key-based), Rex::LibSSH for SFTP-less hosts
#   - cpanm Rex::GPU Rex::Rancher (or -Ilib paths for dev)
#
# For development (both repos checked out):
#   rex -f eg/hetzner-gpu-rke2.Rexfile \
#       -I ../rex-gpu/lib -I lib \
#       -H <IP> deploy

use Rex -feature => ['1.4'];
use Rex::LibSSH;
use Rex::GPU;
use Rex::Rancher;

# --- Configuration ---

my $HOSTNAME   = $ENV{RKE2_HOSTNAME}   || 'rexdemo';
my $DOMAIN     = $ENV{RKE2_DOMAIN}     || 'internal';
my $TIMEZONE   = $ENV{RKE2_TIMEZONE}   || 'Europe/Berlin';
my $TOKEN      = $ENV{RKE2_TOKEN}      || 'rexdemo-cluster-secret';
my $KUBECONFIG = $ENV{KUBECONFIG}      || "$ENV{HOME}/.kube/rexdemo.yaml";

# --- Connection ---

set connection  => 'LibSSH';
set user        => ($ENV{REX_USER} || 'root');
set private_key => ($ENV{REX_KEY}  || "$ENV{HOME}/.ssh/id_ed25519");
set public_key  => ($ENV{REX_KEY}  ? "$ENV{REX_KEY}.pub" : "$ENV{HOME}/.ssh/id_ed25519.pub");
set auth        => 'key';

# ============================================================
#  Main deployment
# ============================================================

desc "Full deployment: prepare → GPU (reboot) → RKE2 → Cilium → device plugin";
task "deploy", sub {
  my $host = connection->server;
  my $tls  = $ENV{RKE2_TLS_SAN} || $host;

  rancher_deploy_server(
    distribution    => 'rke2',
    gpu             => 1,
    reboot          => 1,
    hostname        => $HOSTNAME,
    domain          => $DOMAIN,
    timezone        => $TIMEZONE,
    token           => $TOKEN,
    tls_san         => $tls,
    kubeconfig_file => $KUBECONFIG,
  );

  untaint_node(kubeconfig => $KUBECONFIG);

  say "";
  say "Done!";
  say "  export KUBECONFIG=$KUBECONFIG";
};

# ============================================================
#  Individual steps (for debugging / re-running)
# ============================================================

desc "Step 1: Prepare node only";
task "prepare", sub {
  prepare_node(
    hostname => $HOSTNAME,
    domain   => $DOMAIN,
    timezone => $TIMEZONE,
  );
};

desc "Step 2: GPU detect + install (with reboot)";
task "gpu", sub {
  gpu_setup(containerd_config => 'rke2', reboot => 1);
};

desc "Step 3: RKE2 + Cilium + device plugin (node must be prepared)";
task "rke2", sub {
  my $host = connection->server;
  my $tls  = $ENV{RKE2_TLS_SAN} || $host;

  install_server(
    distribution    => 'rke2',
    token           => $TOKEN,
    tls_san         => $tls,
    kubeconfig_file => $KUBECONFIG,
  );

  wait_for_api(kubeconfig => $KUBECONFIG);
  install_cilium(distribution => 'rke2');
  deploy_nvidia_device_plugin(kubeconfig => $KUBECONFIG);
  untaint_node(kubeconfig => $KUBECONFIG);
};

desc "Untaint control-plane node (allow workload scheduling)";
task "untaint", sub {
  untaint_node(kubeconfig => $KUBECONFIG);
};

# ============================================================
#  Post-deploy: registry update
# ============================================================

desc "Update registries.yaml (after deploying registry into cluster)";
task "add_registry", sub {
  my $registry_ip = $ENV{REGISTRY_IP} or die "Set REGISTRY_IP env var\n";

  update_registries(
    distribution => 'rke2',
    registries   => {
      mirrors => {
        'docker.io' => {
          endpoint => ["http://$registry_ip:5000"],
        },
        'registry.internal' => {
          endpoint => ["http://$registry_ip:5000"],
        },
      },
    },
  );
  say "Registries updated — docker.io and registry.internal → $registry_ip:5000";
};

# ============================================================
#  Info / status tasks
# ============================================================

desc "Get node join token";
task "get_token", sub {
  say get_token('rke2');
};

desc "Check GPU status on the host";
task "gpu_status", sub {
  say "=== nvidia-smi ===";
  say run("nvidia-smi 2>&1", auto_die => 0) || "(not available)";

  say "\n=== Kernel modules ===";
  say run("lsmod | grep nvidia", auto_die => 0) || "(none loaded)";

  say "\n=== Container toolkit ===";
  say run("nvidia-ctk --version 2>&1", auto_die => 0) || "(not installed)";

  say "\n=== containerd nvidia config ===";
  say run("cat /etc/containerd/conf.d/99-nvidia.toml 2>/dev/null || echo '(not configured)'", auto_die => 0);
};

desc "Check cluster + GPU status via K8s API (uses local kubeconfig)";
task "status", sub {
  -f $KUBECONFIG or die "No kubeconfig at $KUBECONFIG — run deploy first\n";

  use Kubernetes::REST::Kubeconfig;
  my $api   = Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $KUBECONFIG)->api;
  my $nodes = eval { $api->list('Node') };
  if ($@) {
    say "Cannot reach cluster API: $@";
    return;
  }

  say "=== Nodes ===";
  for my $node (@{ $nodes->items }) {
    my $name   = $node->metadata->name;
    my @conds  = @{ $node->status->conditions // [] };
    my ($ready) = grep { ($_->{type} // '') eq 'Ready' } @conds;
    my $status  = ($ready && ($ready->{status} // '') eq 'True') ? 'Ready' : 'NotReady';
    my $alloc   = $node->status->allocatable // {};
    my $gpu     = $alloc->{'nvidia.com/gpu'} // '0';
    my $cpu     = $alloc->{cpu}              // '?';
    my $mem     = $alloc->{memory}           // '?';
    printf "  %-20s  %-10s  cpu=%-6s  mem=%-12s  nvidia.com/gpu=%s\n",
      $name, $status, $cpu, $mem, $gpu;
  }

  say "\n=== Cilium ===";
  say run("KUBECONFIG=$KUBECONFIG cilium status --brief 2>/dev/null || echo '(cilium CLI not available)'", auto_die => 0);

  say "\n=== Registries ===";
  say run("cat /etc/rancher/rke2/registries.yaml 2>/dev/null || echo '(not configured)'", auto_die => 0);
};

1;
