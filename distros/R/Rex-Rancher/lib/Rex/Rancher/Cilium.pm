# ABSTRACT: Cilium CNI installation for Rancher Kubernetes distributions

package Rex::Rancher::Cilium;
our $VERSION = '0.003';
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
use Rex::Rancher::Distribution;
use Rex::Rancher::Options;
use YAML::PP;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_cilium
  upgrade_cilium
  ensure_gateway_api_crds
);

# The pair kubernetes-ocp runs live (OCP::Versions). Cilium 1.20 is e2e
# tested on Kubernetes 1.33-1.36, the CLI supports Cilium 1.16 and newer.
use constant CILIUM_VERSION     => '1.20.0';
use constant CILIUM_CLI_VERSION => 'v0.19.7';

# Cilium 1.20 requires TLSRoute and BackendTLSPolicy at v1, which the
# Gateway API bundles carry from this version.
use constant GATEWAY_API_MIN_FOR_1_20 => 'v1.6.1';

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

# Cilium's running configuration: the agent reads it from this ConfigMap
# (the chart renders ipam.mode as "ipam" and the pool list, space-separated,
# as "cluster-pool-ipv4-cidr"), whatever the Helm release values say.
use constant CILIUM_CONFIGMAP => 'cilium-config';

# Default for wait: how long install_cilium/upgrade_cilium wait for the
# cilium DaemonSet and the cilium-operator to be ready, and the poll step.
use constant WAIT_DURATION => 600;
use constant WAIT_INTERVAL => 5;

# Addresses that name the node itself. k3s agents serve the API on
# 127.0.0.1:6444, not 6443, so on k3s k8sServiceHost must not be one of these.
my %LOOPBACK = map { $_ => 1 } qw( 127.0.0.1 localhost ::1 );



sub install_cilium {
  my (%opts) = @_;
  my $o = _resolve_opts(%opts);

  Rex::Logger::info("Installing Cilium $o->{version} on " . $o->{dist}->name . " cluster");

  my $api     = $o->{kubeconfig} ? _api($o->{kubeconfig}) : undef;
  my $release = $api ? _read_release($api) : undef;
  _refuse_stuck_release($release);

  # A Cilium on the cluster keeps its IPAM mode, pool, k8sServiceHost and
  # operator replicas unless the caller asked for them -- whatever the
  # release state: a failed or pending install can have left cilium-config
  # and pods behind, and the ConfigMap is what those pods run with. Read and
  # settled before the host is touched, so a refusal leaves it as it was.
  if ($api) {
    my $running = _read_running($api, $release);
    _adopt_running($o, $running);
    _settle_version($o, $running->{version});
  }
  _require_k8s_service_host($o);
  _check_gateway_api_version($o);

  _install_cilium_cli($o->{cli_version});

  my $crds_applied = $o->{gateway_api}
    ? _ensure_gateway_api_crds($api, $o->{gateway_api_version}, $o->{gateway_api_channel})
    : 0;

  my $values_file = _write_helm_values($o);

  unless ($api) {
    _install_unchecked($o, $values_file);
    return;
  }

  my $action = _release_action($release, $o->{version}, $o->{values});

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

  _wait_ready($api, $o->{wait_duration}) if $o->{wait};

  Rex::Logger::info("Cilium $o->{version} ready on " . $o->{dist}->name . " cluster");
}


sub upgrade_cilium {
  my (%opts) = @_;

  # First, so no other option error hides it and nothing reaches the host:
  # an upgrade applies our values over a running Cilium, and only the API
  # tells which IPAM mode and pool it runs.
  die "upgrade_cilium needs kubeconfig (a local kubeconfig the API answers "
    . "through): without it the running IPAM mode and pool cannot be checked, "
    . "and an upgrade that switches a cluster-pool Cilium to kubernetes IPAM "
    . "(the rke2 default) costs every pod its address. Pass the kubeconfig "
    . "rancher_deploy_server saved (kubeconfig_file)\n" unless $opts{kubeconfig};

  my $o = _resolve_opts(%opts);

  Rex::Logger::info("Upgrading Cilium to $o->{version} on " . $o->{dist}->name . " cluster");

  my $api     = _api($o->{kubeconfig});
  my $release = _read_release($api);
  _require_deployed_release($release);
  my $running = _read_running($api, $release);
  _adopt_running($o, $running);
  _settle_version($o, $running->{version});
  _require_k8s_service_host($o);
  _check_gateway_api_version($o);

  _install_cilium_cli($o->{cli_version});

  my $crds_applied = $o->{gateway_api}
    ? _ensure_gateway_api_crds($api, $o->{gateway_api_version}, $o->{gateway_api_channel})
    : 0;

  my $values_file = _write_helm_values($o);
  _run_cilium(_cilium_command('upgrade', $o, $values_file), 'upgrade');

  _restart_operator($api) if $crds_applied;

  _wait_ready($api, $o->{wait_duration}) if $o->{wait};

  Rex::Logger::info("Cilium upgraded to $o->{version} on " . $o->{dist}->name . " cluster");
}


sub ensure_gateway_api_crds {
  my (%opts) = @_;

  die "ensure_gateway_api_crds needs kubeconfig (a local kubeconfig the API "
    . "answers through)\n" unless $opts{kubeconfig};
  die "ensure_gateway_api_crds needs version (e.g. v1.2.0), matching what "
    . "Cilium supports\n" unless $opts{version};
  my $channel = _gateway_api_channel($opts{channel});

  my $api = _api($opts{kubeconfig});
  my $applied = _ensure_gateway_api_crds($api, $opts{version}, $channel);
  _restart_operator($api) if $applied;
  return $applied;
}


sub validate_cilium_opts {
  my (%opts) = @_;
  _require_k8s_service_host(_resolve_opts(%opts));
  return 1;
}

#
# Option resolution (pure — dies before anything touches the host)
#

sub _resolve_opts {
  my (%opts) = @_;

  my $dist         = Rex::Rancher::Distribution->new_for($opts{distribution});
  my $helm_values  = $opts{helm_values} // {};
  my $gateway_api  = $opts{gateway_api} ? 1 : 0;
  my $wait         = $opts{wait} ? 1 : 0;
  my $duration     = $opts{wait_duration} // WAIT_DURATION;
  my $cluster_cidr = Rex::Rancher::Options->check_cluster_cidr($opts{cluster_cidr});
  my $ipam_mode    = Rex::Rancher::Options->check_ipam_mode($opts{ipam_mode});

  die "helm_values must be a hashref\n" unless ref $helm_values eq 'HASH';

  # Two answers to one question: helm_values would win the merge and make
  # ipam_mode a silent no-op.
  if (defined $ipam_mode && ref $helm_values->{ipam} eq 'HASH'
      && defined $helm_values->{ipam}{mode} && $helm_values->{ipam}{mode} ne $ipam_mode) {
    die "ipam_mode $ipam_mode and helm_values ipam.mode $helm_values->{ipam}{mode} "
      . "contradict each other: give one of them\n";
  }

  die "k8s_service_host is k3s-only: rke2 serves the API on 127.0.0.1:6443 "
    . "on every node\n" if !$dist->needs_k8s_service_host && defined $opts{k8s_service_host};

  my $channel = $opts{gateway_api_channel} // 'experimental';
  if ($gateway_api) {
    die "gateway_api needs kubeconfig (a local kubeconfig the API answers "
      . "through): the CRDs are applied via Kubernetes::REST\n" unless $opts{kubeconfig};
    die "gateway_api needs gateway_api_version (e.g. v1.2.0), matching what "
      . "Cilium supports\n" unless $opts{gateway_api_version};
    $channel = _gateway_api_channel($channel);
  }

  if ($wait) {
    die "wait needs kubeconfig (a local kubeconfig the API answers through): "
      . "readiness is read via Kubernetes::REST\n" unless $opts{kubeconfig};
    die "wait_duration must be a whole number of seconds above 0\n"
      unless $duration =~ /\A[1-9][0-9]*\z/;
  }

  my $values = _helm_values($dist, $gateway_api, $helm_values,
    $opts{k8s_service_host}, $cluster_cidr, $ipam_mode);

  my $o = {
    dist                => $dist,
    version             => $opts{version}     // CILIUM_VERSION,
    version_pinned      => defined $opts{version} ? 1 : 0,
    cli_version         => $opts{cli_version} // CILIUM_CLI_VERSION,
    api_server          => $opts{api_server},
    kubeconfig          => $opts{kubeconfig},
    gateway_api         => $gateway_api,
    gateway_api_version => $opts{gateway_api_version},
    gateway_api_channel => $channel,
    wait                => $wait,
    wait_duration       => $duration,
    values              => $values,
    cluster_cidr        => $cluster_cidr,
    ipam_mode           => $ipam_mode,
    explicit            => _explicit_values($helm_values, $opts{k8s_service_host}),
  };

  # With a kubeconfig a running Cilium's k8sServiceHost is read later, so
  # the check waits for that; without one it can only come from the caller.
  _require_k8s_service_host($o) unless $opts{kubeconfig};

  # A pinned version is the one installed; the default may still give way
  # to a running Cilium (_settle_version), so it is checked after that.
  _check_gateway_api_version($o) if $o->{version_pinned};

  return $o;
}

sub _gateway_api_channel {
  my ($channel) = @_;
  $channel //= 'experimental';
  die "gateway_api_channel must be 'standard' or 'experimental'\n"
    unless $channel eq 'standard' || $channel eq 'experimental';
  return $channel;
}

# kube-proxy replacement on k3s: Cilium must reach the API server before
# any Service works, on agents too, where 127.0.0.1:6443 does not exist.
sub _require_k8s_service_host {
  my ($o) = @_;
  return unless $o->{dist}->needs_k8s_service_host;

  my $host = $o->{values}{k8sServiceHost} // '';
  die "install_cilium on k3s needs k8s_service_host, the control plane "
    . "address every node reaches the API at on port 6443 (k3s agents serve "
    . "it on 127.0.0.1:6444, so localhost does not work)"
    . ( length $host ? ", got '$host'" : '' ) . "\n"
    if !length $host || $LOOPBACK{lc $host};
}

# Which values the caller set, as opposed to our defaults: only defaults
# give way to what a running Cilium already uses. A non-hash where a hash
# belongs counts as setting everything below it. cluster_cidr is not a
# requested pool, nor ipam_mode a requested mode: they are what a fresh
# install gets, and a running Cilium's pool and mode win over them (with a
# warning, in _adopt_running).
sub _explicit_values {
  my ($hv, $k8s_service_host) = @_;

  my $ipam = $hv->{ipam};
  my $ipam_all = exists $hv->{ipam} && ref $ipam ne 'HASH';
  my $op = ref $ipam eq 'HASH' ? $ipam->{operator} : undef;
  my $operator = $hv->{operator};

  return {
    ipam_mode => ( $ipam_all || ( ref $ipam eq 'HASH' && exists $ipam->{mode} ) ) ? 1 : 0,
    pool      => ( $ipam_all || ( ref $ipam eq 'HASH' && exists $ipam->{operator}
                   && ( ref $op ne 'HASH' || exists $op->{clusterPoolIPv4PodCIDRList} ) ) ) ? 1 : 0,
    k8s_service_host  => ( defined $k8s_service_host || exists $hv->{k8sServiceHost} ) ? 1 : 0,
    operator_replicas => ( exists $hv->{operator}
                   && ( ref $operator ne 'HASH' || exists $operator->{replicas} ) ) ? 1 : 0,
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

  return "KUBECONFIG=" . $o->{dist}->kubeconfig . " " . join(" ", @cmd);
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
        . "to reconcile them (upgrade_cilium needs it too)", 'warn');
      return;
    }
    die "cilium install failed: " . ($out // '') . "\n";
  }

  Rex::Logger::info("Cilium $o->{version} installed on " . $o->{dist}->name . " cluster");
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

  _refuse_stuck_release($release);

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

  # A pending install gets here only without a deployed revision (an
  # interrupted first install): _refuse_stuck_release died on the others.
  return 'reinstall'
    if $status eq 'pending-install'
    || $status eq 'uninstalling'
    || $status eq 'uninstalled';

  die "Helm release " . RELEASE_NAME . " is in unexpected state '$status'\n";
}

# A pending upgrade or rollback, or a pending install over a deployed
# revision (Helm itself does not produce one): a Helm operation hangs over
# the revision that carries the pod network, and a reinstall would purge
# that revision with the rest. So this dies instead, in install_cilium and
# upgrade_cilium right after the release is read, before the host is
# touched. A pending install without a deployed revision is an interrupted
# first install and passes.
sub _refuse_stuck_release {
  my ($release) = @_;
  return unless $release;
  my $status = $release->{status};
  _die_release_stuck($release)
    if $status eq 'pending-upgrade' || $status eq 'pending-rollback'
    || ( $status eq 'pending-install' && $release->{has_deployed} );
}

# Helm refuses any operation on a release while another one is pending on
# it: an earlier run was interrupted, or another deploy still runs. The
# revision below it still carries the pod network, so nothing is done
# automatically. install_cilium and upgrade_cilium both die here.
sub _die_release_stuck {
  my ($release) = @_;
  my $revision = $release->{revision} // '?';
  my $secret   = 'sh.helm.release.v1.' . RELEASE_NAME . '.v' . $revision;
  die "Helm release " . RELEASE_NAME . " is stuck in $release->{status} (revision "
    . "$revision): an earlier run was interrupted or "
    . "another deploy is still running. Once none is, delete Secret $secret "
    . "in " . RELEASE_NAMESPACE . " and re-run.\n";
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

#
# The running Cilium (read locally via Kubernetes::REST)
#

# True for the error Kubernetes::REST raises on a 404 response, and only
# for that: "not found" in some other error's body (a webhook, a proxy, a
# name lookup) is not an object that is missing.
sub _is_not_found {
  my ($err) = @_;
  return ( $err // '' ) =~ /\bKubernetes API error \([^)]*\): 404\b/ ? 1 : 0;
}

# undef when the object does not exist; any other API error dies, because
# guessing here is how a cluster-pool cluster gets switched to another mode.
# Namespaced objects live in RELEASE_NAMESPACE; a CustomResourceDefinition
# is cluster-scoped.
sub _get_optional {
  my ($api, $kind, $name) = @_;
  my @ns  = $kind eq 'CustomResourceDefinition' ? () : ( namespace => RELEASE_NAMESPACE );
  my $obj = eval { $api->get($kind, $name, @ns) };
  return $obj if $obj;
  return if !$@ || _is_not_found($@);
  die "Cannot read $kind " . ( @ns ? RELEASE_NAMESPACE . "/" : '' ) . "$name: $@";
}

# What a running Cilium uses, each undef when unknown: the IPAM mode and
# pool from its ConfigMap (not the release values -- a `cilium install`
# without ipam.mode runs the chart default cluster-pool and records no mode),
# k8sServiceHost from the agent's KUBERNETES_SERVICE_HOST, operator.replicas
# from the cilium-operator Deployment (a release that never set it runs the
# chart's default, which the values do not record), else the release values.
sub _read_running {
  my ($api, $release) = @_;

  # Guarded: without a release the deref would autovivify one, and its
  # missing status would warn below.
  my %running = (
    operator_replicas => $release ? eval { $release->{config}{operator}{replicas} } : undef,
  );

  if (my $op = _get_optional($api, 'Deployment', 'cilium-operator')) {
    my $replicas = eval { $op->spec->replicas };
    $running{operator_replicas} = $replicas if defined $replicas;
  }

  if (my $cm = _get_optional($api, 'ConfigMap', CILIUM_CONFIGMAP)) {
    my $data = $cm->data // {};
    # No ipam key: the agent's own default, cluster-pool.
    $running{ipam_mode} = $data->{ipam} // 'cluster-pool';
    my @pool = grep { length } split /[\s,]+/, $data->{'cluster-pool-ipv4-cidr'} // '';
    $running{pool} = \@pool if @pool;
  }

  # The version the agents run: their image tag, else the chart of a
  # deployed release (a failed upgrade's newest revision names the chart
  # that did not make it).
  $running{version} = $release->{chart_version}
    if $release && $release->{status} eq 'deployed' && defined $release->{chart_version};

  if (my $ds = _get_optional($api, 'DaemonSet', RELEASE_NAME)) {
    $running{k8s_service_host} = _daemonset_env($ds, 'KUBERNETES_SERVICE_HOST');
    my $image = _daemonset_version($ds);
    $running{version} = $image if defined $image;
  }

  return \%running;
}

# upgrade_cilium upgrades the deployed revision of Cilium's Helm release:
# `cilium upgrade` is a Helm upgrade without --install. Helm refuses it while
# another operation is pending on the release, and without a deployed
# revision ("has no deployed releases") -- a cilium-config or cilium
# DaemonSet does not change that. Either way it would fail only after the
# CLI, the Gateway API CRDs and the values file are in place, so this dies
# before the host is touched, before the running Cilium is read, and before
# a k3s k8sServiceHost check that would only report a consequence. A pending
# upgrade or rollback, or a pending install over a deployed revision, dies
# as in install_cilium (_refuse_stuck_release). A failed upgrade over a
# deployed revision upgrades again.
sub _require_deployed_release {
  my ($release) = @_;
  my $status = $release ? $release->{status} : '';

  _refuse_stuck_release($release);

  return if $release && $release->{has_deployed};

  die "upgrade_cilium found no deployed revision of Helm release " . RELEASE_NAME
    . " in " . RELEASE_NAMESPACE . " ("
    . ( $release ? "latest revision " . ( $release->{revision} // '?' ) . " is $status" : 'no release' )
    . "): cilium upgrade upgrades a deployed Helm release and cannot install "
    . "one, whether or not cilium-config or the cilium DaemonSet exist. "
    . ( $release
      ? "Use install_cilium, which removes the release left behind and installs Cilium again\n"
      : "Install Cilium with install_cilium\n" );
}

# The cilium-agent image tag as a version (quay.io/cilium/cilium:v1.20.0@sha256:...
# gives 1.20.0), or undef when the tag is no version (a digest only, latest).
sub _daemonset_version {
  my ($ds) = @_;
  my $containers = eval { $ds->spec->template->spec->containers } // [];
  for my $c (grep { $_->name eq 'cilium-agent' } @$containers) {
    my ($tag) = ( $c->image // '' ) =~ m{:v?(\d+\.\d+\.\d+[^\@/:]*)(?:\@|\z)};
    return $tag if defined $tag;
  }
  return;
}

sub _daemonset_env {
  my ($ds, $name) = @_;
  my $containers = eval { $ds->spec->template->spec->containers } // [];
  for my $c (sort { ($b->name eq 'cilium-agent') <=> ($a->name eq 'cilium-agent') } @$containers) {
    for my $env (@{ $c->env // [] }) {
      return $env->value if $env->name eq $name && defined $env->value && length $env->value;
    }
  }
  return;
}

# Fold the running configuration into $o->{values} wherever the caller left
# a default, and die where the caller asked for something a running Cilium
# cannot switch to. Nothing running reads as an empty $running, which
# changes nothing. Pure but for the cluster_cidr and ipam_mode warnings.
sub _adopt_running {
  my ($o, $running) = @_;
  my %values   = %{ $o->{values} };
  my $explicit = $o->{explicit};

  if (defined( my $mode = $running->{ipam_mode} )) {
    my %ipam = ref $values{ipam} eq 'HASH' ? %{ $values{ipam} } : ();
    my $want = $ipam{mode};

    if ($explicit->{ipam_mode}) {
      die "Cilium runs ipam.mode $mode (ConfigMap " . RELEASE_NAMESPACE . "/"
        . CILIUM_CONFIGMAP . "), the requested values ipam.mode "
        . ( $want // 'unset' ) . ": Cilium cannot change the IPAM mode of a "
        . "running cluster (pods lose their addresses). Redeploy the cluster, "
        . "or leave ipam.mode out of helm_values to keep it.\n"
        if ref $values{ipam} eq 'HASH' && ( $want // '' ) ne $mode;
    }
    else {
      # ipam_mode, like the distribution's default, is the mode of a fresh
      # install; only the caller's ipam_mode is worth a warning.
      _warn_ipam_mode_kept($o->{ipam_mode}, $mode)
        if defined $o->{ipam_mode} && $o->{ipam_mode} ne $mode;
      $ipam{mode} = $mode if ref $values{ipam} eq 'HASH' || !exists $values{ipam};
    }

    if (ref $values{ipam} eq 'HASH' || !exists $values{ipam}) {
      my %op = ref $ipam{operator} eq 'HASH' ? %{ $ipam{operator} } : ();
      if ($explicit->{pool}) {
        my $pool = $op{clusterPoolIPv4PodCIDRList};
        my @want = ref $pool eq 'ARRAY' ? @$pool : defined $pool ? ($pool) : ();
        die "Cilium's cluster-pool is @{ $running->{pool} } (ConfigMap "
          . RELEASE_NAMESPACE . "/" . CILIUM_CONFIGMAP . "), the requested "
          . "clusterPoolIPv4PodCIDRList @want: Cilium cannot move the pool of a "
          . "running cluster. Redeploy the cluster, or leave the pool out of "
          . "helm_values to keep it.\n"
          if $mode eq 'cluster-pool' && $running->{pool}
          && join(' ', sort @want) ne join(' ', sort @{ $running->{pool} });
      }
      else {
        # Our default pool gives way: the running one in cluster-pool mode,
        # none otherwise (without a readable one the chart's default runs,
        # and stays). cluster_cidr is such a default: it only says what a
        # fresh install gets.
        _warn_cluster_cidr_kept($o->{cluster_cidr}, $running->{pool})
          if $mode eq 'cluster-pool' && defined $o->{cluster_cidr};
        delete $op{clusterPoolIPv4PodCIDRList};
        $op{clusterPoolIPv4PodCIDRList} = [ @{ $running->{pool} } ]
          if $mode eq 'cluster-pool' && $running->{pool};
      }
      if (%op) { $ipam{operator} = \%op } else { delete $ipam{operator} }
      $values{ipam} = \%ipam;
    }
  }

  $values{k8sServiceHost} = $running->{k8s_service_host}
    if $o->{dist}->needs_k8s_service_host && !$explicit->{k8s_service_host}
    && defined $running->{k8s_service_host};

  if (!$explicit->{operator_replicas} && defined $running->{operator_replicas}) {
    my %operator = ref $values{operator} eq 'HASH' ? %{ $values{operator} } : ();
    $operator{replicas} = $running->{operator_replicas};
    $values{operator} = \%operator;
  }

  $o->{values} = \%values;
  return $o;
}

# cluster_cidr on a running cluster-pool Cilium with another (or an
# unreadable) pool: the running pool stays, loudly. Not fatal -- the caller
# (kubernetes-ocp passes its pod_cidr on every run) cannot tell a fresh
# cluster from an old one, and dying would make an old cluster undeployable.
sub _warn_cluster_cidr_kept {
  my ($cidr, $pool) = @_;
  return if $pool && @$pool == 1 && $pool->[0] eq $cidr;

  Rex::Logger::info("cluster_cidr $cidr is not applied: Cilium already runs "
    . "cluster-pool " . ( $pool ? "@$pool" : "with the chart's default pool" )
    . " (ConfigMap " . RELEASE_NAMESPACE . "/" . CILIUM_CONFIGMAP . "), and the "
    . "pool of a running cluster cannot move. Keeping the running pool; "
    . "redeploy the cluster to use $cidr", 'warn');
}

# ipam_mode on a running Cilium in another mode: the running mode stays,
# loudly, for the same reason as the pool above -- the caller may not know
# whether the cluster is fresh.
sub _warn_ipam_mode_kept {
  my ($want, $mode) = @_;
  Rex::Logger::info("ipam_mode $want is not applied: Cilium already runs "
    . "ipam.mode $mode (ConfigMap " . RELEASE_NAMESPACE . "/" . CILIUM_CONFIGMAP
    . "), and the IPAM mode of a running cluster cannot change. Keeping $mode; "
    . "redeploy the cluster to use $want", 'warn');
}

# Cilium upgrades and rolls back one minor version at a time (its upgrade
# guide: the only tested path is between consecutive minors). Against the
# version a Cilium on the cluster runs:
#   - pinned: at most one minor away, either way; more dies before the host
#     is touched, naming the step to take;
#   - default: a patch release of the running minor is taken; a newer minor
#     or an older version is not -- the running version is kept, a newer
#     minor with a warning. The default is what a fresh install gets, as
#     for rke2/k3s's own version: a re-run after a library upgrade must not
#     jump a cluster several minors or pull it back.
# Nothing running, or a version that does not parse: nothing to compare.
sub _settle_version {
  my ($o, $running) = @_;
  return unless defined $running;
  my @have = _minor_version($running) or return;
  my @want = _minor_version($o->{version}) or return;

  my $apart = $want[0] != $have[0] ? 99 : abs($want[1] - $have[1]);

  if ($o->{version_pinned}) {
    return if $apart <= 1;
    my $step = $want[0] == $have[0]
      ? "$have[0]." . ( $want[1] > $have[1] ? $have[1] + 1 : $have[1] - 1 )
      : 'the next minor';
    die "Cilium runs " . _norm_version($running) . ", version "
      . _norm_version($o->{version}) . " is more than one minor version away: "
      . "Cilium upgrades and rolls back one minor at a time. Go to the latest "
      . "$step.x first, then on\n";
  }

  my $cmp = _cmp_version($o->{version}, $running);
  return if $cmp > 0 && $apart == 0;    # a newer patch of the running minor
  return if $cmp == 0;

  if ($cmp > 0) {
    Rex::Logger::info("Cilium runs " . _norm_version($running) . "; the default "
      . _norm_version($o->{version}) . " is a newer minor version and is not "
      . "applied to a running Cilium. Keeping " . _norm_version($running)
      . "; pass version (cilium_version) to upgrade, one minor at a time", 'warn');
  }
  else {
    Rex::Logger::info("Cilium runs " . _norm_version($running) . ", newer than "
      . "the default " . _norm_version($o->{version}) . "; keeping it");
  }
  $o->{version} = _norm_version($running);
  return $o;
}

# (major, minor) of 1.20.0 / v1.20.0-rc.1, or () when it is no version.
sub _minor_version {
  my ($v) = @_;
  return ( ( $v // '' ) =~ /\Av?(\d+)\.(\d+)(?:\.\d+)?/ );
}

# <=> on the numeric major.minor.patch; anything after it is ignored.
sub _cmp_version {
  my ($x, $y) = @_;
  my @x = ( ( $x // '' ) =~ /\Av?(\d+)\.(\d+)(?:\.(\d+))?/ );
  my @y = ( ( $y // '' ) =~ /\Av?(\d+)\.(\d+)(?:\.(\d+))?/ );
  for my $i (0 .. 2) {
    my $c = ( $x[$i] // 0 ) <=> ( $y[$i] // 0 );
    return $c if $c;
  }
  return 0;
}

# Cilium 1.20 refuses to start its Gateway controller on a bundle older than
# v1.6.1 (TLSRoute and BackendTLSPolicy at v1). Checked on the version that
# will run, before the host is touched.
sub _check_gateway_api_version {
  my ($o) = @_;
  return unless $o->{gateway_api};
  my @cilium = _minor_version($o->{version}) or return;
  return unless $cilium[0] > 1 || ( $cilium[0] == 1 && $cilium[1] >= 20 );
  return if _cmp_version($o->{gateway_api_version}, GATEWAY_API_MIN_FOR_1_20) >= 0;
  die "Cilium " . _norm_version($o->{version}) . " needs Gateway API "
    . GATEWAY_API_MIN_FOR_1_20 . " or newer (TLSRoute and BackendTLSPolicy at "
    . "v1), gateway_api_version is $o->{gateway_api_version}: raise it, or pin "
    . "version (cilium_version) to a Cilium that supports it\n";
}

#
# Readiness: the cilium DaemonSet and the cilium-operator Deployment
#

sub _sleep { sleep $_[0] }

sub _wait_ready {
  my ($api, $duration) = @_;

  my $attempts = int(($duration + WAIT_INTERVAL - 1) / WAIT_INTERVAL) || 1;
  Rex::Logger::info("Waiting up to ${duration}s for Cilium to be ready");

  my $state;
  for my $i (1 .. $attempts) {
    # Missing is a state to wait out; any other API error (401, 403, no
    # connection) dies now instead of reading as "not found" for 600s.
    $state = _readiness(
      scalar _get_optional($api, 'DaemonSet', RELEASE_NAME),
      scalar _get_optional($api, 'Deployment', 'cilium-operator'),
    );
    if ($state->{ready}) {
      Rex::Logger::info("  Cilium ready: $state->{detail}");
      return 1;
    }
    Rex::Logger::info("  $state->{detail} ($i/$attempts)");
    _sleep(WAIT_INTERVAL) if $i < $attempts;
  }

  die "Cilium was not ready within ${duration}s: $state->{detail}. Check the "
    . "cilium and cilium-operator pods in " . RELEASE_NAMESPACE . " (events, "
    . "logs), or `cilium status` on the server\n";
}

# Pure: ready when the DaemonSet has rolled out its current generation to
# every node it wants and all of those pods are ready, and the operator has
# all its replicas updated and ready.
sub _readiness {
  my ($ds, $op) = @_;
  my ($ds_ok, $ds_txt) = (0, "DaemonSet " . RELEASE_NAMESPACE . "/cilium not found");
  my ($op_ok, $op_txt) = (0, "Deployment " . RELEASE_NAMESPACE . "/cilium-operator not found");

  if ($ds) {
    my $st      = $ds->status;
    my $desired = $st ? $st->desiredNumberScheduled // 0 : 0;
    my $ready   = $st ? $st->numberReady // 0 : 0;
    my $updated = $st ? $st->updatedNumberScheduled // 0 : 0;
    my $current = ( $st ? $st->observedGeneration // 0 : 0 ) >= ( $ds->metadata->generation // 0 );
    $ds_ok  = $current && $desired > 0 && $ready == $desired && $updated == $desired;
    $ds_txt = "cilium $ready/$desired ready, $updated/$desired updated"
      . ( $current ? '' : ', rollout not observed yet' );
  }

  if ($op) {
    my $st      = $op->status;
    my $want    = ( $op->spec ? $op->spec->replicas : undef ) // 1;
    my $ready   = $st ? $st->readyReplicas // 0 : 0;
    my $updated = $st ? $st->updatedReplicas // 0 : 0;
    my $current = ( $st ? $st->observedGeneration // 0 : 0 ) >= ( $op->metadata->generation // 0 );
    $op_ok  = $current && $ready >= $want && $updated >= $want;
    $op_txt = "cilium-operator $ready/$want ready, $updated/$want updated"
      . ( $current ? '' : ', rollout not observed yet' );
  }

  return { ready => ( $ds_ok && $op_ok ) ? 1 : 0, detail => "$ds_txt; $op_txt" };
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
  run "KUBECONFIG=" . $o->{dist}->kubeconfig . " cilium uninstall --wait=false 2>&1", auto_die => 0;

  # Already gone is what we want; any other API error dies before the
  # install, which Helm would refuse over a Secret left behind anyway.
  for my $name (@{ $release->{secrets} }) {
    eval { $api->delete('Secret', $name, namespace => RELEASE_NAMESPACE); 1 }
      or _is_not_found($@)
      or die "Cannot delete Secret " . RELEASE_NAMESPACE . "/$name: $@";
  }
}

sub _verify_daemonset {
  my ($api) = @_;

  die "cilium install reported success but DaemonSet "
    . RELEASE_NAMESPACE . "/cilium does not exist\n"
    unless _get_optional($api, 'DaemonSet', RELEASE_NAME);
}

sub _restart_operator {
  my ($api) = @_;
  return unless $api;

  # No operator (yet): nothing to restart. Any other API error dies -- a
  # 403 here used to skip the restart silently, leaving the operator on the
  # old CRDs.
  _get_optional($api, 'Deployment', 'cilium-operator') or return;

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
  my ($api, $version, $channel) = @_;

  _refuse_rke2_gateway_api_chart($api);

  # Missing means apply; an unreadable probe dies instead of reading as
  # missing.
  my $probe = _get_optional($api, 'CustomResourceDefinition', GATEWAY_API_PROBE_CRD);
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

  # Not visible yet is waited out; any other API error dies at once
  # instead of reading as "not Established" for 30s.
  for (1 .. 30) {
    my $crd = _get_optional($api, 'CustomResourceDefinition', $name);
    my $conditions = $crd && $crd->status ? $crd->status->conditions // [] : [];
    return 1 if grep {
      ($_->type // '') eq 'Established' && ($_->status // '') eq 'True'
    } @$conditions;
    _sleep(1);
  }
  die "CustomResourceDefinition $name was not Established within 30s\n";
}

#
# Helm values generation
#

# The defaults both distributions share, the distribution's own
# (cilium_helm_defaults: cni.exclusive, k8sServiceHost, the IPAM mode and
# pool) over them, then gatewayAPI, then the caller's values on top.
sub _helm_values {
  my ($dist, $gateway_api, $extra, $k8s_service_host, $cluster_cidr, $ipam_mode) = @_;

  my $values = _merge_values({
    cni => {
      binPath  => $dist->cni_bin_dir,
      confPath => $dist->cni_conf_dir,
    },
    operator             => { replicas => 1 },
    kubeProxyReplacement => JSON()->true,
    k8sServicePort       => '6443',
  }, $dist->cilium_helm_defaults(
    cluster_cidr     => $cluster_cidr,
    k8s_service_host => $k8s_service_host,
    ipam_mode        => $ipam_mode,
  ));

  $values->{gatewayAPI} = { enabled => JSON()->true } if $gateway_api;

  return _merge_values($values, $extra // {});
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

  my $values_file = "/tmp/cilium-values-" . $o->{dist}->name . ".yaml";
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

version 0.003

=head1 SYNOPSIS

  use Rex::Rancher::Cilium;
  use JSON::MaybeXS;    # JSON()->true below

  # Install Cilium on an RKE2 cluster (defaults to version 1.20.0)
  install_cilium(
    distribution => 'rke2',
  );

  # Install, upgrade or leave alone -- decided from the Helm release,
  # read through the local kubeconfig; with Gateway API and extra values
  install_cilium(
    distribution        => 'rke2',
    kubeconfig          => "$ENV{HOME}/.kube/mycluster.yaml",
    version             => '1.20.0',
    gateway_api         => 1,
    gateway_api_version => 'v1.6.1',
    helm_values         => { hubble => { relay => { enabled => JSON()->true } } },
  );

  # Install Cilium on a K3s cluster with explicit version
  install_cilium(
    distribution     => 'k3s',
    k8s_service_host => '10.0.0.1',    # the control plane, not localhost
    version          => '1.20.0',
    cli_version      => 'v0.19.7',
  );

  # Upgrade an existing Cilium installation, keeping what it runs,
  # and wait until it is ready again
  upgrade_cilium(
    distribution => 'rke2',
    kubeconfig   => "$ENV{HOME}/.kube/mycluster.yaml",
    version      => '1.20.0',
    wait         => 1,
  );

  # Only move the Gateway API CRDs (restarts cilium-operator if applied)
  ensure_gateway_api_crds(
    kubeconfig => "$ENV{HOME}/.kube/mycluster.yaml",
    version    => 'v1.6.1',
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
C<ipam.mode: kubernetes> (or C<ipam_mode>); with C<cluster_cidr> also
C<ipam.operator.clusterPoolIPv4PodCIDRList: [cluster_cidr]>, which Cilium
uses only in C<cluster-pool> mode (C<ipam_mode> or C<helm_values>; under
C<kubernetes> the pods follow the node C<podCIDR>s).

=item K3s

C<kubeProxyReplacement: true>, C<k8sServiceHost:> C<k8s_service_host>,
C<k8sServicePort: "6443">, C<cni.exclusive: true>, C<operator.replicas: 1>,
C<ipam.mode: cluster-pool> (or C<ipam_mode>) with
C<ipam.operator.clusterPoolIPv4PodCIDRList: [10.42.0.0/16]> (K3s's
C<cluster-cidr>; C<cluster_cidr> replaces it).

=back

Both distributions share the same CNI binary/config paths (C</opt/cni/bin>,
C</etc/cni/net.d>). C<gateway_api> adds C<gatewayAPI.enabled: true>, and
C<helm_values> is merged over all of it. C<--set kubeProxyReplacement=true>
is also passed on the command line and wins over any value file. With
C<kubeconfig> and a running Cilium, its IPAM mode, pool, K3s
C<k8sServiceHost> and C<operator.replicas> replace these defaults (see
L</install_cilium>).

=head2 Default versions

The module ships with pinned defaults for reproducibility:
Cilium C<1.20.0> and Cilium CLI C<v0.19.7>, the pair kubernetes-ocp runs.
Override with the C<version> and C<cli_version> options. The default
version is that of a fresh install: a running Cilium of another minor
version keeps its own (see C<version> in L</install_cilium>). The Gateway
API version has no default; see C<gateway_api_version> (v1.6.1 or newer
for Cilium 1.20).

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

=item * C<failed> or C<pending-install> with no C<deployed> revision (a
failed or interrupted first install), C<uninstalling> or C<uninstalled>:
the stale release is removed (C<cilium uninstall>, then its Helm release
Secrets) and Cilium is installed fresh. No working Cilium exists in these
states, so nothing running is taken down. A Secret already gone (404) is
fine; any other API error deleting one dies before the install.

=item * an upgrade that would change C<ipam.mode> (the release sets one
explicitly and the requested values differ): dies before C<cilium upgrade>,
naming both modes. Cilium cannot switch IPAM mode under running pods;
redeploy the cluster, or pass the deployed mode in C<helm_values>.
(With the running configuration below, this only fires when release and
ConfigMap disagree.)

=item * C<pending-upgrade> or C<pending-rollback>, or C<pending-install>
over a C<deployed> revision: dies before the host is touched, with the
message of L</upgrade_cilium>. An earlier run was interrupted or another is
still running, and the deployed revision still carries the pod network; the
message names the Secret to delete once no other deploy is running.

=back

What a Cilium on the cluster runs is read first and kept wherever the
caller did not ask for something else, before anything touches the host.
This does not depend on the release state: a C<failed> or C<pending-install>
release, or none at all, can still have left C<cilium-config> and pods
behind, and the ConfigMap is what those pods run with, so a reinstall uses
it too:

=over

=item * C<ipam.mode> and the pool (C<ipam.operator.clusterPoolIPv4PodCIDRList>)
come from the ConfigMap C<kube-system/cilium-config> (C<ipam>,
C<cluster-pool-ipv4-cidr>), not from the release values: a Cilium installed
without an explicit mode runs the chart default C<cluster-pool>, and the
C<kubernetes> default of the RKE2 values must not switch it (its pods would
lose their addresses). A ConfigMap without C<ipam> counts as
C<cluster-pool>, the agent's default. The default pool gives way to the
running one; in any other mode it is dropped.

=item * a mode or pool the caller set in C<helm_values> that differs from
the running one dies, naming both: Cilium cannot change either under running
pods. The pool is compared only in C<cluster-pool> mode, as a set.

=item * C<cluster_cidr> is the pool of a fresh install, not a requested one:
on a running C<cluster-pool> Cilium with another pool the running pool is
kept, with a warning naming both.

=item * C<ipam_mode> is likewise the mode of a fresh install: on a running
Cilium in another mode the running mode (and, in C<cluster-pool>, its pool)
is kept, with a warning naming both. Only C<ipam.mode> in C<helm_values>
counts as requested and dies on a difference.

=item * on K3s without C<k8s_service_host> (or C<helm_values-E<gt>{k8sServiceHost}>),
C<k8sServiceHost> is the C<KUBERNETES_SERVICE_HOST> of the running
C<cilium> DaemonSet.

=item * C<operator.replicas> keeps the C<spec.replicas> of the running
C<cilium-operator> Deployment (without one, the release's value) instead of
the default C<1>, unless C<helm_values> sets it.

=back

Any API error other than a 404 while reading these dies rather than fall
back to the defaults.

After a fresh install the C<cilium> DaemonSet must exist, or it dies: the
CLI has been seen to exit 0 without creating anything. An API error other
than a 404 reading it dies naming that error. With C<wait>, the
function returns only once Cilium is ready (see there).

Without C<kubeconfig> the release state cannot be read, and the previous
behaviour applies: C<cilium install> runs, and its "cannot re-use a name"
error (the release already exists) counts as success, with a warning that
version and values were not reconciled. Helm refuses to install over the
existing release, so nothing about the running Cilium changes on this path;
changing it needs C<kubeconfig>, here or with L</upgrade_cilium>.

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

Both distributions have been run live through Rex::Rancher. The k3s values
are those kubernetes-ocp verified live (k3s v1.36.4+k3s1, Cilium 1.20.0,
Gateway API v1.6.1 standard), with the Cilium and CLI versions this module
defaults to; Rex::Rancher's k3s path has since brought Cilium up live with
C<k8s_service_host> (see L<Rex::Rancher::Distribution::K3s>).

Options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>.

=item C<version>

Cilium version to install, e.g. C<1.20.0>. Default: C<1.20.0>.

Cilium upgrades and rolls back one minor version at a time. With
C<kubeconfig>, the version a Cilium on the cluster runs (the C<cilium-agent>
image tag of the C<cilium> DaemonSet, else the chart of a C<deployed>
release) is read before the host is touched:

=over

=item * a C<version> more than one minor version from it, up or down, dies
naming the minor to go to first;

=item * without C<version>, the default applies only to a fresh install
and to a newer patch of the running minor. A running Cilium of an older
minor keeps its version, with a warning (pass C<version> to upgrade, one
minor at a time); one newer than the default keeps its version too. So a
re-run after a Rex::Rancher upgrade never moves a cluster by more than a
patch release.

=back

Without C<kubeconfig> nothing is compared, and nothing running changes
(see below). Cilium C<1.18> and newer need Linux 5.10 or newer on every
node (4.18 on RHEL 8.10); Cilium C<1.20> is tested on Kubernetes 1.33 to
1.36.

=item C<cli_version>

Cilium CLI version to download, e.g. C<v0.19.7>. Default: C<v0.19.7>, which
supports Cilium 1.16 and newer; an older Cilium needs an older CLI.

=item C<k8s_service_host>

K3s only, and required there: the control plane address Cilium reaches the
API server at on port 6443 from every node (C<k8sServiceHost>), e.g. the
server's IP or a name in its certificate. A loopback address dies, because
K3s agents serve the API on C<127.0.0.1:6444>, not 6443.
C<helm_values-E<gt>{k8sServiceHost}> may take its place, and with
C<kubeconfig> a running Cilium's own address does (see above); without any of
them it dies before the host is touched.
L<Rex::Rancher/rancher_deploy_server> passes the first C<tls_san>. Passing
it on RKE2 dies: RKE2 uses C<127.0.0.1>, which works on every node there.

=item C<cluster_cidr>

The cluster's pod network, the server's C<cluster_cidr> (see
L<Rex::Rancher::Server/install_server>): one IPv4 CIDR, anything else dies
before the host is touched. Written as Cilium's pool,
C<ipam.operator.clusterPoolIPv4PodCIDRList>, unless C<helm_values> sets one.
It takes effect only in C<cluster-pool> mode: on K3s, in place of
C<10.42.0.0/16>, and on RKE2 with C<ipam_mode =E<gt> 'cluster-pool'> (or
that mode in C<helm_values>). RKE2's default stays C<ipam.mode: kubernetes>, where Cilium ignores the pool value
and pods get addresses from the node C<podCIDR>s the cluster cuts from its
C<cluster-cidr> -- the same range, reached through the server's
C<config.yaml>. It is the pool of a fresh install: a running
C<cluster-pool> Cilium keeps its own pool, with a warning when it differs
(see above). L<Rex::Rancher/rancher_deploy_server> passes its own
C<cluster_cidr>.

=item C<ipam_mode>

Cilium's IPAM mode (C<ipam.mode>) on a fresh install: C<kubernetes> or
C<cluster-pool>, anything else dies before the host is touched (other
modes need more than a mode and stay with C<helm_values>). Default:
L<Rex::Rancher::Distribution/default_ipam_mode>, C<kubernetes> on RKE2 and
C<cluster-pool> on K3s. With C<cluster-pool>, C<cluster_cidr> is the pool on
RKE2 too. A Cilium already running (C<kube-system/cilium-config> readable
through C<kubeconfig>) keeps its own mode, with a warning when it differs
(see above); without C<kubeconfig> nothing running is changed anyway. An
C<ipam.mode> in C<helm_values> that differs from it dies as contradictory.
L<Rex::Rancher/rancher_deploy_server> passes its own C<ipam_mode>.

=item C<api_server>

Kubernetes API server URL, passed as C<--api-server> to the CLI. Optional;
the CLI uses the kubeconfig's server address if omitted.

=item C<kubeconfig>

Local path to the cluster kubeconfig (as saved by
L<Rex::Rancher/rancher_deploy_server>). Enables the release-state handling
and the running-configuration reads above and is required for
C<gateway_api> and C<wait>. Optional.

=item C<wait>

If true, wait after install, upgrade or no-op until Cilium is ready: the
C<cilium> DaemonSet has rolled out its current generation to every node it
schedules on and all those pods are ready, and every C<cilium-operator>
replica is updated and ready. Requires C<kubeconfig>; read from the local
machine. Dies after C<wait_duration> naming the last state (pods ready and
updated of each); a missing DaemonSet or Deployment is waited out, any other
API error (no access, no connection) dies at once. Default: off, which only
checks that the DaemonSet exists after a fresh install.

=item C<wait_duration>

Seconds C<wait> waits, a whole number above 0. Default: C<600>. Only used
with C<wait>.

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
restarted so it picks up the new CRDs. Only a 404 counts as missing: an API
error reading the probe CRD (C<gateways.gateway.networking.k8s.io>), a CRD
waited on to become Established, or the C<cilium-operator> Deployment dies
at once instead of applying, waiting out 30s, or skipping the restart.

RKE2 v1.37+ ships the same CRDs as its own chart, C<rke2-gateway-api-crd>,
which would overwrite them. L<Rex::Rancher/rancher_deploy_server> disables it
for you; calling this directly, put it in C<install_server>'s C<disable>.
While that chart's Helm release exists this dies before applying anything,
naming the way out: disable the chart and restart C<rke2-server> (Helm
uninstalls it but keeps its C<gateway.networking.k8s.io> CRDs, so Gateways
and routes survive), or use RKE2's CRDs via C<helm_values> without
C<gateway_api>.

=item C<gateway_api_version>

Gateway API release to apply, e.g. C<v1.6.1>. It must match what the Cilium
C<version> supports; there is no default because the two are version-locked.
Cilium 1.20 and newer need C<v1.6.1> or newer (C<TLSRoute> and
C<BackendTLSPolicy> at v1); an older one with such a Cilium dies before the
host is touched -- for a pinned C<version> already in option checks, for the
default once it is known whether a running Cilium keeps an older version.

=item C<gateway_api_channel>

C<experimental> (default) or C<standard>. What Cilium needs depends on both
versions. Cilium up to 1.16 requires C<TLSRoute> v1alpha2, which only the
experimental channel carries. Cilium 1.17 to 1.19 require standard-channel
CRDs only and handle C<TLSRoute> v1alpha2 when it is there; before Gateway
API v1.5 the standard channel has no C<TLSRoute>, so C<standard> costs TLS
passthrough. Gateway API v1.5 moved C<TLSRoute> (as v1) into the standard
channel, v1.6 also C<TCPRoute> and C<UDPRoute>; Cilium 1.20 requires
C<TLSRoute> v1 and C<BackendTLSPolicy> v1, which the v1.5+ standard channel
carries. The default stays C<experimental>: it is the channel every Cilium
version works with, and it keeps C<TLSRoute> v1alpha2 objects of an older
Cilium readable (the v1.6 standard C<TLSRoute> CRD drops that version, and
such objects disappear).

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

C<kubeconfig> is required: without it the function dies before anything
touches the host. It does the same, pointing to L</install_cilium>, when
the Helm release C<cilium> in C<kube-system> has no C<deployed> revision:
C<cilium upgrade> is a Helm upgrade and cannot install, so a ConfigMap
C<kube-system/cilium-config> or a C<cilium> DaemonSet without a deployed
release is not enough. A release left C<failed>, C<pending-install>,
C<uninstalling> or C<uninstalled> without one is what L</install_cilium>
removes and installs again. A release stuck in C<pending-upgrade> or
C<pending-rollback> (or C<pending-install> over a deployed revision) dies
before the host as well, with the message of L</install_cilium> naming the
Secret to delete. A C<failed> upgrade over a deployed revision is upgraded
again. The running
configuration is read and kept exactly as in
L</install_cilium> (IPAM mode and pool from C<kube-system/cilium-config>,
K3s C<k8sServiceHost> from the DaemonSet, C<operator.replicas> from the
C<cilium-operator> Deployment), so an upgrade needs no values the caller has
to look up first, and a change of IPAM mode or pool asked for in
C<helm_values> dies before the host is touched. The version follows the
same one-minor-at-a-time rule as there: pass C<version> to upgrade to a
new minor. Without it, a running Cilium of an older minor keeps its version
(with a warning) and C<cilium upgrade> only re-applies the values.
Without the API none of that can be checked, and the generated values would
be applied as they stand -- on RKE2 the default C<ipam.mode: kubernetes>
switches a C<cluster-pool> cluster and its pods lose their addresses.

Options are the same as L</install_cilium>, C<wait> and C<wait_duration>
included, except that C<kubeconfig> is not optional.

  upgrade_cilium(
    distribution => 'rke2',
    kubeconfig   => "$ENV{HOME}/.kube/mycluster.yaml",
    version      => '1.20.0',
  );

=head2 ensure_gateway_api_crds(%opts)

Apply the Gateway API CRDs of one bundle version and channel, the same way
C<gateway_api> does in L</install_cilium>, without touching Cilium's Helm
release: for a Gateway API pin that moved while Cilium did not. Everything
runs from the local machine through L<Kubernetes::REST>; the remote host is
not used.

The CRDs are skipped when the cluster already carries that bundle version
and channel. When they are applied and a C<cilium-operator> Deployment
exists, it is restarted so it picks up the new CRDs; API errors other than
a 404 die, as with C<gateway_api>. While RKE2's
C<rke2-gateway-api-crd> Helm release exists this dies before applying
anything, as C<gateway_api> does. Returns C<1> when the CRDs were applied,
C<0> when they were already current.

Options:

=over

=item C<kubeconfig>

Local path to the cluster kubeconfig. Required.

=item C<version>

Gateway API release, e.g. C<v1.2.0>. Required; it must match what the
running Cilium supports.

=item C<channel>

C<experimental> (default) or C<standard>; see C<gateway_api_channel> in
L</install_cilium>.

=back

  ensure_gateway_api_crds(
    kubeconfig => "$ENV{HOME}/.kube/mycluster.yaml",
    version    => 'v1.2.0',
    channel    => 'standard',
  );

=head2 validate_cilium_opts(%opts)

Check the options of L</install_cilium> without touching anything: dies
with the same message C<install_cilium> would for an unknown distribution,
bad C<helm_values>, C<cluster_cidr>, C<ipam_mode> or C<gateway_api>
settings, and -- also
with C<kubeconfig>, where C<install_cilium> could still read it from a
running Cilium -- a K3s cluster without a usable C<k8s_service_host>.
Returns C<1>. Not exported; L<Rex::Rancher/rancher_deploy_server> calls it
as C<Rex::Rancher::Cilium::validate_cilium_opts> before the node is
prepared.

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
