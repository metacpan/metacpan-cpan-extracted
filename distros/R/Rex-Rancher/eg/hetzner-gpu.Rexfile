# Hetzner bare-metal GPU server → single-node RKE2 cluster
#
# Usage:
#   rex -f eg/hetzner-gpu.Rexfile -H <IP> deploy
#   rex -f eg/hetzner-gpu.Rexfile -H <IP> status
#   rex -f eg/hetzner-gpu.Rexfile -H <IP> untaint
#   rex -f eg/hetzner-gpu.Rexfile -H <IP> gpu
#   rex -f eg/hetzner-gpu.Rexfile -H <IP> gpu_status
#
# Prerequisites:
#   - Fresh Debian/Ubuntu on Hetzner dedicated server with NVIDIA GPU (openSUSE/SLES unverified)
#   - SSH root access (key-based), Rex::LibSSH for SFTP-less hosts
#   - cpanm Rex::GPU Rex::Rancher (or -Ilib paths for dev)
#
# For development (both repos checked out):
#   PERL5LIB=lib:../rex-gpu/lib:$PERL5LIB \
#     rex -f eg/hetzner-gpu.Rexfile -H <IP> deploy

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

desc "GPU detect + install only (with reboot)";
task "gpu", sub {
  gpu_setup(containerd_config => 'rke2', reboot => 1);
};

desc "Untaint control-plane node (allow workload scheduling)";
task "untaint", sub {
  untaint_node(kubeconfig => $KUBECONFIG);
};

# ============================================================
#  Info / status tasks
# ============================================================

desc "Check GPU status on the host";
task "gpu_status", sub {
  say "=== nvidia-smi ===";
  say run("nvidia-smi 2>&1", auto_die => 0) || "(not available)";

  say "\n=== Kernel modules ===";
  say run("lsmod | grep nvidia", auto_die => 0) || "(none loaded)";

  say "\n=== Container toolkit ===";
  say run("nvidia-ctk --version 2>&1", auto_die => 0) || "(not installed)";

  say "\n=== containerd nvidia runtime (generated RKE2 config) ===";
  say run("grep -A3 nvidia /var/lib/rancher/rke2/agent/etc/containerd/config.toml 2>/dev/null || echo '(no nvidia runtime configured)'", auto_die => 0);
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
  say run("KUBECONFIG=/etc/rancher/rke2/rke2.yaml cilium status --brief 2>/dev/null || echo '(cilium CLI not available)'", auto_die => 0);

  say "\n=== Registries ===";
  say run("cat /etc/rancher/rke2/registries.yaml 2>/dev/null || echo '(not configured)'", auto_die => 0);
};

# ============================================================
#  Pre-connect host-key scan (Rex::LibSSH >= 0.004)
# ============================================================
#
# Rex::LibSSH >= 0.004 verifies the server host key against known_hosts
# (CWE-322 fix); before that it never checked. A freshly-installed Hetzner
# box has no known_hosts entry, so the FIRST verified connect would die with
# "host key is not in known_hosts and strict_hostkeycheck is on". This
# 'before ALL' hook runs on the LOCAL machine BEFORE Rex opens the SSH
# connection for any task (Rex runs before-hooks ahead of ->connect) and
# ssh-keyscans the target into known_hosts — which KEEPS host-key
# verification on, rather than disabling it.
#
# It must come after the task definitions: 'before' attaches to tasks that
# already exist.
before 'ALL' => sub {
  my ($server) = @_;
  rancher_scan_known_hosts($server);
};

1;
