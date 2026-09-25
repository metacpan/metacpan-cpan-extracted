# ABSTRACT: Cilium CNI installation for Rancher Kubernetes distributions

package Rex::Rancher::Cilium;
our $VERSION = '0.002';
use v5.14.4;
use warnings;

use HTTP::Tiny;
use IO::Uncompress::Gunzip qw( gunzip $GunzipError );
use JSON::MaybeXS;
use Kubernetes::REST::Kubeconfig;
use MIME::Base64 qw( decode_base64 );
use POSIX qw( strftime );
use Rex::Commands::File;
use Rex::Commands::Gather;
use Rex::Commands::Run;
use Rex::Logger;
use YAML::PP;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_cilium
  upgrade_cilium
);

use constant CILIUM_VERSION     => '1.17.0';
use constant CILIUM_CLI_VERSION => 'v0.16.23';

# The cilium CLI installs a Helm release of this name into this namespace;
# Helm keeps one Secret per revision there (labels owner=helm,name=cilium).
use constant RELEASE_NAME      => 'cilium';
use constant RELEASE_NAMESPACE => 'kube-system';

# Present in both Gateway API channels; its annotations name the bundle
# version and channel that were last applied.
use constant GATEWAY_API_PROBE_CRD => 'gateways.gateway.networking.k8s.io';

# RKE2 v1.37+ ships the Gateway API CRDs as its own Helm chart; the release
# lives in RELEASE_NAMESPACE like Cilium's.
use constant RKE2_GATEWAY_API_RELEASE => 'rke2-gateway-api-crd';

# Addresses that name the node itself. k3s agents serve the API on
# 127.0.0.1:6444, not 6443, so on k3s k8sServiceHost must not be one of these.
my %LOOPBACK = map { $_ => 1 } qw( 127.0.0.1 localhost ::1 );



sub install_cilium {
  my (%opts) = @_;
  my $o = _resolve_opts(%opts);

  Rex::Logger::info("Installing Cilium $o->{version} on $o->{distribution} cluster");

  _install_cilium_cli($o->{cli_version});

  my $api = $o->{kubeconfig} ? _api($o->{kubeconfig}) : undef;
  my $crds_applied = $o->{gateway_api} ? _ensure_gateway_api_crds($api, $o) : 0;

  my $values_file = _write_helm_values($o);

  unless ($api) {
    _install_unchecked($o, $values_file);
    return;
  }

  my $release = _read_release($api);
  my $action  = _release_action($release, $o->{version}, $o->{values});

  if ($action eq 'noop') {
    Rex::Logger::info("  Cilium $o->{version} already deployed with the requested values, nothing to do");
  }
  elsif ($action eq 'upgrade') {
    Rex::Logger::info("  Helm release $release->{status} at "
      . ($release->{chart_version} // 'unknown version') . ", upgrading");
    _run_cilium(_cilium_command('upgrade', $o, $values_file), 'upgrade');
  }
  else {
    _purge_release($api, $o, $release) if $action eq 'reinstall';
    _run_cilium(_cilium_command('install', $o, $values_file), 'install');
    _verify_daemonset($api);
  }

  _restart_operator($api)
    if $crds_applied && ($action eq 'noop' || $action eq 'upgrade');

  Rex::Logger::info("Cilium $o->{version} ready on $o->{distribution} cluster");
}


sub upgrade_cilium {
  my (%opts) = @_;
  my $o = _resolve_opts(%opts);

  Rex::Logger::info("Upgrading Cilium to $o->{version} on $o->{distribution} cluster");

  _install_cilium_cli($o->{cli_version});

  my $api = $o->{kubeconfig} ? _api($o->{kubeconfig}) : undef;
  my $crds_applied = $o->{gateway_api} ? _ensure_gateway_api_crds($api, $o) : 0;

  my $values_file = _write_helm_values($o);
  _run_cilium(_cilium_command('upgrade', $o, $values_file), 'upgrade');

  _restart_operator($api) if $crds_applied;

  Rex::Logger::info("Cilium upgraded to $o->{version} on $o->{distribution} cluster");
}

#
# Option resolution (pure — dies before anything touches the host)
#

sub _resolve_opts {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $paths        = _paths_for($distribution);
  my $helm_values  = $opts{helm_values} // {};
  my $gateway_api  = $opts{gateway_api} ? 1 : 0;
  my $channel      = $opts{gateway_api_channel} // 'experimental';

  die "helm_values must be a hashref\n" unless ref $helm_values eq 'HASH';

  die "k8s_service_host is k3s-only: rke2 serves the API on 127.0.0.1:6443 "
    . "on every node\n" if $distribution eq 'rke2' && defined $opts{k8s_service_host};

  if ($gateway_api) {
    die "gateway_api needs kubeconfig (a local kubeconfig the API answers "
      . "through): the CRDs are applied via Kubernetes::REST\n" unless $opts{kubeconfig};
    die "gateway_api needs gateway_api_version (e.g. v1.2.0), matching what "
      . "Cilium supports\n" unless $opts{gateway_api_version};
    die "gateway_api_channel must be 'standard' or 'experimental'\n"
      unless $channel eq 'standard' || $channel eq 'experimental';
  }

  my $values = _helm_values($distribution, $paths, $gateway_api, $helm_values,
    $opts{k8s_service_host});

  # kube-proxy replacement on k3s: Cilium must reach the API server before
  # any Service works, on agents too, where 127.0.0.1:6443 does not exist.
  if ($distribution eq 'k3s') {
    my $host = $values->{k8sServiceHost} // '';
    die "install_cilium on k3s needs k8s_service_host, the control plane "
      . "address every node reaches the API at on port 6443 (k3s agents serve "
      . "it on 127.0.0.1:6444, so localhost does not work)"
      . ( length $host ? ", got '$host'" : '' ) . "\n"
      if !length $host || $LOOPBACK{lc $host};
  }

  return {
    distribution        => $distribution,
    paths               => $paths,
    version             => $opts{version}     // CILIUM_VERSION,
    cli_version         => $opts{cli_version} // CILIUM_CLI_VERSION,
    api_server          => $opts{api_server},
    kubeconfig          => $opts{kubeconfig},
    gateway_api         => $gateway_api,
    gateway_api_version => $opts{gateway_api_version},
    gateway_api_channel => $channel,
    values              => $values,
  };
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
# Running the CLI on the remote host
#

sub _cilium_command {
  my ($verb, $o, $values_file) = @_;

  my @cmd = (
    "cilium $verb",
    "--version $o->{version}",
    "--helm-values $values_file",
  );
  push @cmd, "--set kubeProxyReplacement=true";
  push @cmd, "--api-server $o->{api_server}" if $o->{api_server};

  return "KUBECONFIG=$o->{paths}{kubeconfig} " . join(" ", @cmd);
}

sub _run_cilium {
  my ($cmd, $what) = @_;

  Rex::Logger::info("Running: $cmd");
  # auto_die => 0 only to put the CLI's output into the error message.
  my $out = run "$cmd 2>&1", auto_die => 0;
  die "cilium $what failed: " . ($out // '') . "\n" if $? != 0;
  return $out;
}

# No local kubeconfig: the release state cannot be read, so keep the old
# contract. "cannot re-use a name that is still in use" is Helm refusing a
# second install of an existing release — on a re-run against a cluster
# that already has Cilium that is the expected outcome, and failing on it
# made every re-deploy die. Version and values are not reconciled here.
sub _install_unchecked {
  my ($o, $values_file) = @_;

  my $cmd = _cilium_command('install', $o, $values_file);
  Rex::Logger::info("Running: $cmd");
  my $out = run "$cmd 2>&1", auto_die => 0;

  if ($? != 0) {
    if (($out // '') =~ /cannot re-use a name/i) {
      Rex::Logger::info("  Cilium already installed (Helm release exists); without "
        . "kubeconfig its version and values are not checked -- pass kubeconfig "
        . "to reconcile them, or use upgrade_cilium", 'warn');
      return;
    }
    die "cilium install failed: " . ($out // '') . "\n";
  }

  Rex::Logger::info("Cilium $o->{version} installed on $o->{distribution} cluster");
}

#
# Helm release state (read locally via Kubernetes::REST)
#

sub _api {
  my ($kubeconfig) = @_;
  return Kubernetes::REST::Kubeconfig->new(
    kubeconfig_path => $kubeconfig,
  )->api;
}

# The release named $name (default: Cilium's), or undef when there is none.
sub _read_release {
  my ($api, $name) = @_;

  my $list = $api->list('Secret',
    namespace     => RELEASE_NAMESPACE,
    labelSelector => 'owner=helm,name=' . ($name // RELEASE_NAME),
  );

  return _release_from_secrets([ map {
    +{
      name    => $_->metadata->name,
      labels  => $_->metadata->labels // {},
      release => ($_->data // {})->{release},
    }
  } @{ $list->items // [] } ]);
}

# Collapse Helm's per-revision Secrets into the state of the release: the
# newest revision's status, chart version and user-supplied values, and
# whether any revision is still 'deployed'. undef when there is no release.
sub _release_from_secrets {
  my ($secrets) = @_;
  return unless @$secrets;

  my @sorted = sort { ($b->{labels}{version} // 0) <=> ($a->{labels}{version} // 0) } @$secrets;
  my $latest  = $sorted[0];
  my $payload = _decode_release($latest->{release}) // {};

  return {
    revision      => $latest->{labels}{version},
    status        => $latest->{labels}{status} // 'unknown',
    chart_version => eval { $payload->{chart}{metadata}{version} },
    config        => $payload->{config} // {},
    has_deployed  => (grep { ($_->{labels}{status} // '') eq 'deployed' } @sorted) ? 1 : 0,
    secrets       => [ map { $_->{name} } @sorted ],
  };
}

# Secret data is base64 (Kubernetes) of base64 (Helm) of gzipped JSON.
# Returns undef when the payload cannot be decoded; the caller then treats
# the chart version as unknown, which leads to an upgrade, never a no-op.
sub _decode_release {
  my ($data) = @_;
  return unless defined $data;

  my $json = eval {
    my $raw = decode_base64(decode_base64($data));
    if (substr($raw, 0, 2) eq "\x1f\x8b") {
      my $plain;
      gunzip(\$raw => \$plain) or die "gunzip: $GunzipError\n";
      $raw = $plain;
    }
    JSON::MaybeXS->new->decode($raw);
  };
  return ref $json eq 'HASH' ? $json : undef;
}

# The decision the whole release handling hangs on. Pure: release state in,
# one of install / noop / upgrade / reinstall out, or a die for the states
# where acting automatically could take down a working pod network.
sub _release_action {
  my ($release, $version, $values) = @_;

  return 'install' unless $release;

  my $status = $release->{status};

  if ($status eq 'deployed') {
    my $same_version = defined $release->{chart_version}
      && _norm_version($release->{chart_version}) eq _norm_version($version);
    return 'noop' if $same_version && _values_subset($values, $release->{config});
    _refuse_ipam_change($release, $values);
    return 'upgrade';
  }

  if ($status eq 'failed') {
    # A failed upgrade leaves the previous revision deployed: upgrade again.
    # A failed first install has nothing deployed: Helm refuses to upgrade it
    # ("has no deployed releases") and to install over it.
    return 'reinstall' unless $release->{has_deployed};
    _refuse_ipam_change($release, $values);
    return 'upgrade';
  }

  return 'reinstall'
    if $status eq 'pending-install'
    || $status eq 'uninstalling'
    || $status eq 'uninstalled';

  if ($status eq 'pending-upgrade' || $status eq 'pending-rollback') {
    my $secret = 'sh.helm.release.v1.' . RELEASE_NAME . '.v' . ($release->{revision} // '?');
    die "Helm release " . RELEASE_NAME . " is stuck in $status (revision "
      . ($release->{revision} // '?') . "): an earlier run was interrupted or "
      . "another deploy is still running. Once none is, delete Secret $secret "
      . "in " . RELEASE_NAMESPACE . " and re-run.\n";
  }

  die "Helm release " . RELEASE_NAME . " is in unexpected state '$status'\n";
}

# Cilium cannot switch IPAM mode under running pods: an upgrade that changes
# ipam.mode leaves them without addresses. Only an ipam.mode the release set
# explicitly is compared; without one the deployed mode is not known here.
sub _refuse_ipam_change {
  my ($release, $values) = @_;

  my $have = eval { $release->{config}{ipam}{mode} };
  my $want = eval { $values->{ipam}{mode} };
  return unless defined $have && defined $want && $have ne $want;

  die "Helm release " . RELEASE_NAME . " runs ipam.mode $have, the requested "
    . "values ipam.mode $want: Cilium cannot change the IPAM mode of a running "
    . "cluster (pods lose their addresses). Redeploy the cluster, or pass "
    . "helm_values => { ipam => { mode => '$have' } } to keep it.\n";
}

sub _norm_version {
  my ($v) = @_;
  $v =~ s/^v//;
  return $v;
}

# True when every value in $want is present with the same value in $have.
# $have is the release's full user config, which carries more than we set
# (the CLI adds its own detected values), so equality would never hold.
sub _values_subset {
  my ($want, $have) = @_;

  if (ref $want eq 'HASH') {
    return 0 unless ref $have eq 'HASH';
    for my $k (keys %$want) {
      return 0 unless exists $have->{$k} && _values_subset($want->{$k}, $have->{$k});
    }
    return 1;
  }
  if (ref $want eq 'ARRAY') {
    return 0 unless ref $have eq 'ARRAY' && @$want == @$have;
    for my $i (0 .. $#$want) {
      return 0 unless _values_subset($want->[$i], $have->[$i]);
    }
    return 1;
  }
  return 0 if ref $have eq 'HASH' || ref $have eq 'ARRAY';
  return _scalar_str($want) eq _scalar_str($have);
}

sub _scalar_str {
  my ($v) = @_;
  return '~' unless defined $v;
  return $v ? 'true' : 'false' if JSON::MaybeXS::is_bool($v);
  return "$v";
}

# Remove a release that holds no working Cilium so a fresh install can run:
# cilium uninstall clears whatever the half-install created, then the Helm
# release Secrets go, since `cilium install` refuses (or silently no-ops)
# while any of them is left.
sub _purge_release {
  my ($api, $o, $release) = @_;

  Rex::Logger::info("  Helm release is $release->{status} with no working Cilium, "
    . "removing it before a fresh install", 'warn');

  # auto_die => 0: on a half-installed release some of what uninstall
  # removes was never created, and it reports that as an error.
  run "KUBECONFIG=$o->{paths}{kubeconfig} cilium uninstall --wait=false 2>&1", auto_die => 0;

  for my $name (@{ $release->{secrets} }) {
    eval { $api->delete('Secret', $name, namespace => RELEASE_NAMESPACE); 1 }
      or do { die $@ unless $@ =~ /\b404\b|not ?found/i };
  }
}

sub _verify_daemonset {
  my ($api) = @_;

  my $ds = eval { $api->get('DaemonSet', 'cilium', namespace => RELEASE_NAMESPACE) };
  die "cilium install reported success but DaemonSet "
    . RELEASE_NAMESPACE . "/cilium does not exist: " . ($@ || 'not found') . "\n"
    unless $ds;
}

sub _restart_operator {
  my ($api) = @_;
  return unless $api;

  my $op = eval { $api->get('Deployment', 'cilium-operator', namespace => RELEASE_NAMESPACE) };
  return unless $op;

  Rex::Logger::info("  Restarting cilium-operator so it picks up the Gateway API CRDs");
  $api->patch('Deployment', 'cilium-operator',
    namespace => RELEASE_NAMESPACE,
    patch     => { spec => { template => { metadata => { annotations => {
      'kubectl.kubernetes.io/restartedAt' => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
    } } } } },
  );
}

#
# Gateway API CRDs
#

sub _gateway_api_url {
  my ($version, $channel) = @_;
  return "https://github.com/kubernetes-sigs/gateway-api/releases/download/"
    . "$version/$channel-install.yaml";
}

# Apply unless the cluster already carries this bundle version and channel.
sub _gateway_api_needs_apply {
  my ($annotations, $version, $channel) = @_;
  return 1 unless $annotations;
  return 1 unless ($annotations->{'gateway.networking.k8s.io/bundle-version'} // '') eq $version;
  return 1 unless ($annotations->{'gateway.networking.k8s.io/channel'} // '') eq $channel;
  return 0;
}

# Returns 1 when CRDs were applied, 0 when they were already current.
sub _ensure_gateway_api_crds {
  my ($api, $o) = @_;
  my ($version, $channel) = @{$o}{qw( gateway_api_version gateway_api_channel )};

  _refuse_rke2_gateway_api_chart($api);

  my $probe = eval { $api->get('CustomResourceDefinition', GATEWAY_API_PROBE_CRD) };
  my $annotations = $probe ? $probe->metadata->annotations : undef;

  unless (_gateway_api_needs_apply($annotations, $version, $channel)) {
    Rex::Logger::info("Gateway API CRDs $version ($channel) already applied");
    return 0;
  }

  my $url = _gateway_api_url($version, $channel);
  Rex::Logger::info("Applying Gateway API CRDs $version ($channel) from $url");

  my $res = HTTP::Tiny->new(verify_SSL => 1)->get($url);
  die "Cannot fetch Gateway API bundle $url: $res->{status} $res->{reason}\n"
    unless $res->{success};

  my @docs = grep { ref $_ eq 'HASH' && $_->{kind} }
    YAML::PP->new(boolean => 'JSON::PP')->load_string($res->{content});
  die "Gateway API bundle $url holds no objects\n" unless @docs;

  # File order: CRDs first, the safe-upgrades admission policy after them.
  $api->ensure($_) for @docs;

  for my $crd (grep { $_->{kind} eq 'CustomResourceDefinition' } @docs) {
    _wait_crd_established($api, $crd->{metadata}{name});
  }

  Rex::Logger::info("Gateway API CRDs $version ($channel) applied");
  return 1;
}

# Two owners would take the CRDs from each other: RKE2's chart applies with
# take-ownership and force-conflicts once pods can run (after Cilium), and
# its safe-upgrades policy then refuses our experimental bundle. Only a live
# release counts: disabling the chart uninstalls it but keeps the CRDs
# (helm.sh/resource-policy: keep), Helm annotations and all.
sub _refuse_rke2_gateway_api_chart {
  my ($api) = @_;
  my $release = _read_release($api, RKE2_GATEWAY_API_RELEASE) or return;

  die "The Gateway API CRDs belong to RKE2's Helm release "
    . RKE2_GATEWAY_API_RELEASE . " ($release->{status}, chart "
    . ($release->{chart_version} // 'unknown') . "), which would overwrite "
    . "what gateway_api applies. Add " . RKE2_GATEWAY_API_RELEASE
    . " to disable and restart rke2-server: the chart is uninstalled, its "
    . "gateway.networking.k8s.io CRDs (and the Gateways and routes) are "
    . "kept. Or drop gateway_api "
    . "and set gatewayAPI.enabled in helm_values to use RKE2's CRDs.\n";
}

sub _wait_crd_established {
  my ($api, $name) = @_;

  for (1 .. 30) {
    my $crd = eval { $api->get('CustomResourceDefinition', $name) };
    my $conditions = $crd && $crd->status ? $crd->status->conditions // [] : [];
    return 1 if grep {
      ($_->type // '') eq 'Established' && ($_->status // '') eq 'True'
    } @$conditions;
    sleep 1;
  }
  die "CustomResourceDefinition $name was not Established within 30s\n";
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
      # Rex::Rancher::Server's k3s cluster-cidr; the pool must match it.
      cluster_cidr => '10.42.0.0/16',
    };
  }
  else {
    die "Unknown distribution: $distribution (expected 'rke2' or 'k3s')\n";
  }
}

#
# Helm values generation
#

# Defaults per distribution, then gatewayAPI, then the caller's values on top.
sub _helm_values {
  my ($distribution, $paths, $gateway_api, $extra, $k8s_service_host) = @_;

  my %values = (
    cni => {
      binPath   => $paths->{cni_bin},
      confPath  => $paths->{cni_conf},
      exclusive => $distribution eq 'rke2' ? JSON()->false : JSON()->true,
    },
    ipam     => { mode => 'kubernetes' },
    operator => { replicas => 1 },
  );

  $values{kubeProxyReplacement} = JSON()->true;
  $values{k8sServicePort}       = '6443';

  if ($distribution eq 'rke2') {
    $values{k8sServiceHost} = '127.0.0.1';
  }
  else {
    # k3s: the control plane address (validated in _resolve_opts), and
    # Cilium's own pool on k3s' cluster-cidr, as kubernetes-ocp k178.
    $values{k8sServiceHost} = $k8s_service_host if defined $k8s_service_host;
    $values{ipam} = {
      mode     => 'cluster-pool',
      operator => { clusterPoolIPv4PodCIDRList => [ $paths->{cluster_cidr} ] },
    };
  }

  $values{gatewayAPI} = { enabled => JSON()->true } if $gateway_api;

  return _merge_values(\%values, $extra // {});
}

# Deep merge, $over wins; hashes merge key by key, anything else replaces.
# Returns a new structure — neither input is modified.
sub _merge_values {
  my ($base, $over) = @_;

  my %out = %$base;
  for my $k (keys %$over) {
    $out{$k} = ref $out{$k} eq 'HASH' && ref $over->{$k} eq 'HASH'
      ? _merge_values($out{$k}, $over->{$k})
      : $over->{$k};
  }
  return \%out;
}

sub _helm_values_yaml {
  my ($values) = @_;
  return YAML::PP->new(boolean => 'JSON::PP')->dump_string($values);
}

sub _write_helm_values {
  my ($o) = @_;

  my $values_file = "/tmp/cilium-values-$o->{distribution}.yaml";
  file $values_file, content => _helm_values_yaml($o->{values});

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

version 0.002

=head1 SYNOPSIS

  use Rex::Rancher::Cilium;
  use JSON::MaybeXS;    # JSON()->true below

  # Install Cilium on an RKE2 cluster (defaults to version 1.17.0)
  install_cilium(
    distribution => 'rke2',
  );

  # Install, upgrade or leave alone -- decided from the Helm release,
  # read through the local kubeconfig; with Gateway API and extra values
  install_cilium(
    distribution        => 'rke2',
    kubeconfig          => "$ENV{HOME}/.kube/mycluster.yaml",
    version             => '1.17.0',
    gateway_api         => 1,
    gateway_api_version => 'v1.2.0',
    helm_values         => { hubble => { relay => { enabled => JSON()->true } } },
  );

  # Install Cilium on a K3s cluster with explicit version
  install_cilium(
    distribution     => 'k3s',
    k8s_service_host => '10.0.0.1',    # the control plane, not localhost
    version          => '1.17.0',
    cli_version      => 'v0.16.23',
  );

  # Upgrade an existing Cilium installation
  upgrade_cilium(
    distribution => 'rke2',
    version      => '1.17.0',
  );

=head1 DESCRIPTION

L<Rex::Rancher::Cilium> provides Cilium CNI installation and upgrade for
Rancher Kubernetes distributions (RKE2 and K3s). The Cilium CLI runs on the
remote server host via SSH; the Helm release state and the Gateway API CRDs
are read and written from the local machine via L<Kubernetes::REST> when a
local C<kubeconfig> is given.

=head2 Prerequisites

The server must already be running with its own CNI switched off in
C<config.yaml>, so that Cilium is the only one: on RKE2 C<cni: none> and
C<disable-kube-proxy: true>, on K3s C<flannel-backend: none>,
C<disable-network-policy: true>, C<disable-kube-proxy: true> and
C<cluster-cidr: 10.42.0.0/16>; on both Cilium takes over kube-proxy's role.
L<Rex::Rancher::Server/install_server> sets these options by default when
C<cilium =E<gt> 1>.

=head2 Helm values

Distribution-specific Helm values are written to
C</tmp/cilium-values-E<lt>distE<gt>.yaml>:

=over

=item RKE2

C<kubeProxyReplacement: true>, C<k8sServiceHost: 127.0.0.1>,
C<k8sServicePort: "6443">, C<cni.exclusive: false>, C<operator.replicas: 1>,
C<ipam.mode: kubernetes>.

=item K3s

C<kubeProxyReplacement: true>, C<k8sServiceHost:> C<k8s_service_host>,
C<k8sServicePort: "6443">, C<cni.exclusive: true>, C<operator.replicas: 1>,
C<ipam.mode: cluster-pool> with
C<ipam.operator.clusterPoolIPv4PodCIDRList: [10.42.0.0/16]> (K3s's
C<cluster-cidr>).

=back

Both distributions share the same CNI binary/config paths (C</opt/cni/bin>,
C</etc/cni/net.d>). C<gateway_api> adds C<gatewayAPI.enabled: true>, and
C<helm_values> is merged over all of it. C<--set kubeProxyReplacement=true>
is also passed on the command line and wins over any value file.

=head2 Default versions

The module ships with pinned defaults for reproducibility:
Cilium C<1.17.0> and Cilium CLI C<v0.16.23>. Override with the
C<version> and C<cli_version> options. The Gateway API version has no
default; see C<gateway_api_version>.

=head1 FUNCTIONS

=head2 install_cilium(%opts)

Install Cilium CNI on a Rancher Kubernetes cluster (RKE2 or K3s), or bring
an existing installation to the requested version and values.

The Cilium CLI binary is downloaded from GitHub to C</usr/local/bin/cilium>
on the remote host (skipped if the correct version is already present).
Distribution-appropriate Helm values, merged with C<helm_values>, are written
to C</tmp/cilium-values-E<lt>distE<gt>.yaml> and handed to the CLI.

With C<kubeconfig> (a I<local> kubeconfig path), the existing Helm release
is read from the cluster via L<Kubernetes::REST> before anything is
installed, and the outcome depends on its state:

=over

=item * no release: C<cilium install>.

=item * C<deployed> at the requested version with every requested value
already in effect: nothing is done.

=item * C<deployed> at another version, or with a requested value
differing: C<cilium upgrade>.

=item * C<failed> with an earlier revision still C<deployed> (a failed
upgrade): C<cilium upgrade> again.

=item * C<failed> with no C<deployed> revision (a failed first install),
C<pending-install>, C<uninstalling> or C<uninstalled>: the stale release is
removed (C<cilium uninstall>, then its Helm release Secrets) and Cilium is
installed fresh. No working Cilium exists in these states, so nothing
running is taken down.

=item * an upgrade that would change C<ipam.mode> (the release sets one
explicitly and the requested values differ): dies before C<cilium upgrade>,
naming both modes. Cilium cannot switch IPAM mode under running pods;
redeploy the cluster, or pass the deployed mode in C<helm_values>.

=item * C<pending-upgrade> or C<pending-rollback>: dies. An earlier run was
interrupted or another is still running, and the deployed revision still
carries the pod network; the message names the Secret to delete once no
other deploy is running.

=back

After a fresh install the C<cilium> DaemonSet must exist, or it dies: the
CLI has been seen to exit 0 without creating anything.

Without C<kubeconfig> the release state cannot be read, and the previous
behaviour applies: C<cilium install> runs, and its "cannot re-use a name"
error (the release already exists) counts as success, with a warning that
version and values were not reconciled. Use L</upgrade_cilium> to change an
existing installation in that case.

On both distributions C<kubeProxyReplacement=true> is passed to enable
Cilium's eBPF-based kube-proxy replacement, so the server config must have
switched off the distribution's CNI and kube-proxy: on RKE2 C<cni: none> and
C<disable-kube-proxy: true>, on K3s C<flannel-backend: none>,
C<disable-network-policy: true>, C<disable-kube-proxy: true> and
C<cluster-cidr: 10.42.0.0/16> (L<Rex::Rancher::Server/install_server> writes
these). Cilium then needs an API server address that works before any
Service does, on every node: on RKE2 that is C<127.0.0.1:6443>, where servers
and agents alike serve it. K3s agents serve it on C<127.0.0.1:6444> instead,
so on K3s Cilium is given the control plane's own address,
C<k8s_service_host>, and dies without one.

B<rke2 is the verified distribution.> The k3s values are those
kubernetes-ocp verified live (k3s v1.36.4+k3s1, Cilium 1.20.0, Gateway API
v1.6.1 standard); Rex::Rancher's k3s path has not been run live itself and
defaults to Cilium 1.17.0.

Options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>.

=item C<version>

Cilium version to install, e.g. C<1.17.0>. Default: C<1.17.0>.

=item C<cli_version>

Cilium CLI version to download, e.g. C<v0.16.23>. Default: C<v0.16.23>.

=item C<k8s_service_host>

K3s only, and required there: the control plane address Cilium reaches the
API server at on port 6443 from every node (C<k8sServiceHost>), e.g. the
server's IP or a name in its certificate. A loopback address dies, because
K3s agents serve the API on C<127.0.0.1:6444>, not 6443.
C<helm_values-E<gt>{k8sServiceHost}> may take its place.
L<Rex::Rancher/rancher_deploy_server> passes the first C<tls_san>. Passing
it on RKE2 dies: RKE2 uses C<127.0.0.1>, which works on every node there.

=item C<api_server>

Kubernetes API server URL, passed as C<--api-server> to the CLI. Optional;
the CLI uses the kubeconfig's server address if omitted.

=item C<kubeconfig>

Local path to the cluster kubeconfig (as saved by
L<Rex::Rancher/rancher_deploy_server>). Enables the release-state handling
above and is required for C<gateway_api>. Optional.

=item C<helm_values>

Hashref of additional Helm values, deep-merged over the defaults (hashes
merge key by key, anything else replaces the default). Optional.

=item C<gateway_api>

If true, apply the Gateway API CRDs before Cilium and set
C<gatewayAPI.enabled: true>. Default: off. Requires C<kubeconfig> and
C<gateway_api_version>. The CRDs are fetched from the
kubernetes-sigs/gateway-api GitHub release on the machine running Rex and
applied through L<Kubernetes::REST> (no C<kubectl>). They are skipped when
the cluster already carries that bundle version and channel; when they are
applied to a cluster with a running C<cilium-operator>, the operator is
restarted so it picks up the new CRDs.

RKE2 v1.37+ ships the same CRDs as its own chart, C<rke2-gateway-api-crd>,
which would overwrite them. L<Rex::Rancher/rancher_deploy_server> disables it
for you; calling this directly, put it in C<install_server>'s C<disable>.
While that chart's Helm release exists this dies before applying anything,
naming the way out: disable the chart and restart C<rke2-server> (Helm
uninstalls it but keeps its C<gateway.networking.k8s.io> CRDs, so Gateways
and routes survive), or use RKE2's CRDs via C<helm_values> without
C<gateway_api>.

=item C<gateway_api_version>

Gateway API release to apply, e.g. C<v1.2.0>. It must match what the Cilium
C<version> supports; there is no default because the two are version-locked.

=item C<gateway_api_channel>

C<experimental> (default) or C<standard>. What Cilium needs depends on both
versions. Cilium up to 1.16 requires C<TLSRoute> v1alpha2, which only the
experimental channel carries. Cilium 1.17 to 1.19 require standard-channel
CRDs only and handle C<TLSRoute> v1alpha2 when it is there; before Gateway
API v1.5 the standard channel has no C<TLSRoute>, so C<standard> costs TLS
passthrough. Gateway API v1.5 moved C<TLSRoute> (as v1) into the standard
channel, v1.6 also C<TCPRoute> and C<UDPRoute>; Cilium 1.20 requires
C<TLSRoute> v1 and C<BackendTLSPolicy> v1, which the v1.5+ standard channel
carries. The default stays C<experimental> so the default Cilium keeps
C<TLSRoute>.

Gateway API v1.5+ ships an admission policy that refuses experimental CRDs
on top of standard ones: a cluster that started on C<standard> cannot move
to C<experimental>.

=back

=head2 upgrade_cilium(%opts)

Upgrade an existing Cilium installation to a new version using
C<cilium upgrade>, unconditionally. The Cilium CLI is updated first if
needed. The same Helm values generation logic as L</install_cilium> is used,
and C<gateway_api> applies the CRDs the same way (restarting a running
C<cilium-operator> when they were applied).

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
