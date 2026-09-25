# ABSTRACT: Rancher Kubernetes server (control plane) installation

package Rex::Rancher::Server;
our $VERSION = '0.002';
use v5.14.4;
use warnings;

use Rex::Commands::File;
use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Logger;
use YAML::PP;
use JSON::MaybeXS;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_server
  update_registries
  get_kubeconfig
  get_token
);

my %PATHS = (
  rke2 => {
    config_dir   => '/etc/rancher/rke2/',
    service      => 'rke2-server',
    install_url  => 'https://get.rke2.io',
    kubeconfig   => '/etc/rancher/rke2/rke2.yaml',
    token_file   => '/var/lib/rancher/rke2/server/node-token',
    server_token => '/var/lib/rancher/rke2/server/token',
    disable      => ['rke2-ingress-nginx', 'rke2-traefik', 'rke2-traefik-crd'],
    binary       => 'rke2',
    release_url  => 'https://github.com/rancher/rke2/releases/download',
    artifact_dir => '/tmp/rke2-artifacts',
    env_file     => '/etc/default/rke2-server',
  },
  k3s => {
    config_dir   => '/etc/rancher/k3s/',
    service      => 'k3s',
    install_url  => 'https://get.k3s.io',
    kubeconfig   => '/etc/rancher/k3s/k3s.yaml',
    token_file   => '/var/lib/rancher/k3s/server/node-token',
    server_token => '/var/lib/rancher/k3s/server/token',
    disable      => ['traefik', 'servicelb'],
    # k3s' built-in default, written out with cilium because Cilium's
    # cluster-pool IPAM has to hand out the same range (Rex::Rancher::Cilium
    # _paths_for holds the same value, t/server-config.t keeps them equal).
    cluster_cidr => '10.42.0.0/16',
    binary       => 'k3s',
    release_url  => 'https://github.com/k3s-io/k3s/releases/download',
    artifact_dir => '/tmp/k3s-artifacts',
    # No env_file: k3s needs no PATH for the NVIDIA runtime lookup
    # (see _nvidia_runtime_path).
  },
);


sub _paths {
  my ($distribution) = @_;
  $distribution //= 'rke2';

  die "Unknown distribution: $distribution (expected 'rke2' or 'k3s')\n"
    unless exists $PATHS{$distribution};

  return { %{$PATHS{$distribution}} };
}


sub install_server {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  Rex::Logger::info(
    "k3s has not been run live through Rex::Rancher; rke2 is the verified "
      . "distribution.", "warn")
    if $distribution eq 'k3s';
  my $paths        = _paths($distribution);
  # Validated before anything touches the host (the token lookup reads it).
  my $method       = _install_method($opts{install_method}, $opts{version});
  my $token        = _resolve_token($paths, $opts{token});
  my $server       = $opts{server};
  my $tls_san      = $opts{tls_san};
  my $node_labels  = $opts{node_labels};
  my $registries   = $opts{registries};
  my $cilium       = exists $opts{cilium} ? $opts{cilium} : 1;
  my $version      = $opts{version};
  my $node_name    = $opts{node_name};
  my $disable      = $opts{disable};

  Rex::Logger::info("Installing $distribution server (control plane)...");

  # Ensure config directory exists
  file $paths->{config_dir}, ensure => 'directory';

  # Write config.yaml
  _write_config($paths, $distribution, $token, $server, $tls_san, $node_labels, $cilium,
    $node_name, $disable);

  # Write registries.yaml if configured
  if ($registries) {
    _generate_registries_yaml($paths->{config_dir}, $registries);
  }

  # Before the installer: rke2 looks for the NVIDIA runtime only when its
  # service starts.
  _nvidia_runtime_path($paths) if $opts{nvidia_runtime_path};

  # Install and start
  if ($distribution eq 'k3s') {
    _install_k3s($paths, $server, $version, $method);
  }
  else {
    _install_rke2($paths, $version, $method);
  }

  Rex::Logger::info("$distribution server installation complete");

  return 1;
}


sub update_registries {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $registries   = $opts{registries} or die "update_registries requires 'registries' option\n";
  my $paths        = _paths($distribution);

  Rex::Logger::info("Updating registries.yaml for $distribution");

  _generate_registries_yaml($paths->{config_dir}, $registries);

  # Restart containerd to pick up new config
  if ($distribution eq 'rke2') {
    run "systemctl restart rke2-server.service 2>/dev/null || systemctl restart rke2-agent.service 2>/dev/null",
      auto_die => 0;
  }
  else {
    run "systemctl restart k3s.service 2>/dev/null || systemctl restart k3s-agent.service 2>/dev/null",
      auto_die => 0;
  }

  Rex::Logger::info("Registries updated, containerd restarted");
}


sub get_kubeconfig {
  my ($distribution) = @_;
  my $paths = _paths($distribution);

  Rex::Logger::info("Retrieving kubeconfig from " . $paths->{kubeconfig});

  my $content = run "cat " . $paths->{kubeconfig}, auto_die => 1;
  return $content;
}


sub get_token {
  my ($distribution) = @_;
  my $paths = _paths($distribution);

  Rex::Logger::info("Retrieving node token from " . $paths->{token_file});

  my $content = run "cat " . $paths->{token_file}, auto_die => 1;
  chomp $content;
  return $content;
}

# Never rotate the token a control plane is already sealed with: the datastore
# encryption key derives from it at bootstrap and is only re-checked at the
# NEXT start, so a fresh token in config.yaml arms a fatal "bootstrap data
# already found and encrypted with different token" on the next restart.
sub _resolve_token {
  my ($paths, $given) = @_;
  return $given if defined $given;
  my $existing = _existing_server_token($paths);
  if (defined $existing) {
    Rex::Logger::info("Reusing existing cluster token from " . $paths->{server_token});
    return $existing;
  }
  return _generate_token();
}

# Read over the exec channel (no SFTP). A missing or unreadable file means
# "fresh server" and degrades to undef; it must never abort the install.
sub _existing_server_token {
  my ($paths) = @_;
  my $out = run "cat " . $paths->{server_token} . " 2>/dev/null", auto_die => 0;
  return unless $? == 0 && defined $out;
  $out =~ s/\s+\z//;
  return length $out ? $out : undef;
}

sub _generate_token {
  my $token = run "head -c 36 /dev/urandom | base64 | tr -d '\\n/+='  | head -c 48",
    auto_die => 0;
  chomp $token;
  die "Failed to generate random token\n" unless $token && length($token) >= 32;
  Rex::Logger::info("Generated cluster token (auto)");
  return $token;
}

#
# Config file generation
#

sub _build_server_config {
  my ($distribution, $token, $server, $tls_san, $node_labels, $cilium,
    $node_name, $disable) = @_;

  $distribution //= 'rke2';

  my %config = (
    'token' => $token,
  );

  # With cilium, Cilium is the only CNI and replaces kube-proxy on both
  # distributions (Rex::Rancher::Cilium wires kubeProxyReplacement). rke2:
  # cni:none + disable-kube-proxy. k3s: Flannel, the embedded network policy
  # controller and kube-proxy go; cluster-cidr is stated so Cilium's
  # cluster-pool gets the same range (as kubernetes-ocp k178, verified live
  # there). All server-side; k3s agents take them from the server.
  if ($cilium) {
    if ($distribution eq 'rke2') {
      $config{'cni'}                = 'none';
      $config{'disable-kube-proxy'} = JSON()->true;
    }
    else {
      $config{'flannel-backend'}        = 'none';
      $config{'disable-network-policy'} = JSON()->true;
      $config{'disable-kube-proxy'}     = JSON()->true;
      $config{'cluster-cidr'}           = _paths($distribution)->{cluster_cidr};
    }
  }

  # Packaged components to switch off. Undef means the per-distribution
  # default from %PATHS (rke2: ingress-nginx + traefik charts, unknown chart
  # names are ignored by RKE2; k3s: traefik + servicelb, formerly --disable
  # flags on the k3s installer line -- config.yaml carries the same flag,
  # keeps caller-supplied names out of the shell, and matches rke2). An
  # explicit empty list disables nothing. Independent of cilium.
  my @disable = !defined $disable       ? @{ _paths($distribution)->{disable} }
              : ref $disable eq 'ARRAY' ? @{$disable}
              :                           split(/,/, $disable);
  $config{'disable'} = \@disable if @disable;

  $config{server} = $server if $server;
  $config{'node-name'} = $node_name if $node_name;

  if ($tls_san) {
    my @sans = ref $tls_san eq 'ARRAY' ? @{$tls_san} : split(/,/, $tls_san);
    $config{'tls-san'} = \@sans;
  }

  if ($node_labels) {
    my @labels = ref $node_labels eq 'ARRAY' ? @{$node_labels} : ($node_labels);
    $config{'node-label'} = \@labels;
  }

  return \%config;
}

sub _write_config {
  my ($paths, $distribution, $token, $server, $tls_san, $node_labels, $cilium,
    $node_name, $disable) = @_;

  my $config =
    _build_server_config($distribution, $token, $server, $tls_san, $node_labels, $cilium,
      $node_name, $disable);

  my $config_file = $paths->{config_dir} . "config.yaml";
  Rex::Logger::info("Writing config to $config_file");

  _write_secret_file($config_file,
    YAML::PP->new(boolean => 'JSON::PP')->dump_string($config));
}

#
# RKE2 installation (pre-download artifact approach)
#

sub _install_rke2 {
  my ($paths, $version, $method) = @_;

  if (($method // 'script') eq 'artifact') {
    my $spec = _fetch_artifacts('rke2', $version);
    Rex::Logger::info("Installing RKE2 from verified artifact $spec->{asset}...");
    # auto_die => 1: with an artifact path the script takes its tarball
    # method, which has no GPG key import (the Rocky 10 noise below is the
    # RPM method's), so a non-zero exit here is a real failure.
    run _rke2_artifact_install_cmd($spec, $version), auto_die => 1;
  }
  else {
    Rex::Logger::info("Installing RKE2 via install script...");
    # Download and run the RKE2 install script.
    # auto_die => 0: the script emits GPG key import info on STDERR which can
    # cause a non-zero exit on some distros (Rocky 10). Verify via rpm/dpkg instead.
    run _rke2_server_install_cmd($paths, $version), auto_die => 0;
  }
  my $check = run "command -v rke2 2>/dev/null", auto_die => 0;
  die "RKE2 install script failed — rke2 binary not found\n"
    unless $check && $check =~ /rke2/;
  # The binary being there is not enough when a version is pinned: a failed
  # pinned upgrade (swallowed above) leaves the old one in place.
  _verify_installed_version('rke2', $version);

  # Enable and start the service
  run "systemctl enable " . $paths->{service}, auto_die => 1;
  # --no-block: return immediately; RKE2 first start pulls many images and
  # exceeds systemctl's default 90s activation timeout.
  run "systemctl start --no-block " . $paths->{service}, auto_die => 1;

  _wait_for_service($paths->{service});

  # Then wait until kubeconfig is written — API readiness is checked locally
  # by the caller via Rex::Rancher::K8s::wait_for_api after saving the file.
  _wait_for_kubeconfig($paths);
}

sub _rke2_server_install_cmd {
  my ($paths, $version) = @_;

  my $env_str = $version ? "INSTALL_RKE2_VERSION=$version " : '';
  return "curl -sfL " . $paths->{install_url} . " | ${env_str}sh -";
}

#
# K3s installation (simple curl | sh approach)
#

sub _install_k3s {
  my ($paths, $server, $version, $method) = @_;

  # No K3S_TOKEN here: the token is already in config.yaml (written before the
  # installer runs, same as rke2), and anything on this line shows up in ps.
  if (($method // 'script') eq 'artifact') {
    my $spec = _fetch_artifacts('k3s', $version);
    Rex::Logger::info("Installing K3s from verified artifact $spec->{asset}...");
    run _k3s_binary_place_cmd($spec), auto_die => 1;
    run _k3s_artifact_install_cmd($spec, $server, $version, 'server'), auto_die => 1;
  }
  else {
    Rex::Logger::info("Installing K3s via install script...");
    run _k3s_server_install_cmd($paths, $server, $version), auto_die => 1;
  }
  _verify_installed_version('k3s', $version);

  # INSTALL_K3S_SKIP_START: the script's own `systemctl restart` of the
  # Type=notify unit blocks until k3s is up, forever for an HA join that
  # cannot reach its first server. Restart (a re-run still picks up a new
  # binary and config.yaml) with --no-block, then the bounded wait.
  run "systemctl enable " . $paths->{service}, auto_die => 1;
  run "systemctl restart --no-block " . $paths->{service}, auto_die => 1;
  _wait_for_service($paths->{service});
  _wait_for_kubeconfig($paths);
}

# traefik/servicelb are disabled via config.yaml `disable:` (see
# _build_server_config), not as --disable flags here.
sub _k3s_server_install_cmd {
  my ($paths, $server, $version) = @_;

  my @env;
  push @env, "K3S_URL=$server"              if $server;
  push @env, "INSTALL_K3S_VERSION=$version" if $version;
  push @env, 'INSTALL_K3S_SKIP_START=true';   # started by _install_k3s
  my $env_str = join('', map { "$_ " } @env);
  return "curl -sfL " . $paths->{install_url}
    . " | ${env_str}sh -s - server"
    . " --write-kubeconfig-mode=644";
}

#
# NVIDIA runtime lookup: a PATH for the rke2 unit.
# Shared with Rex::Rancher::Agent (rke2-agent has the same unit shape).
#

# systemd's own default directories, not the SSH session's PATH: this becomes
# the environment of a service running as root.
my $RUNTIME_PATH_LINE = 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

# rke2-server/-agent.service carry no Environment= and read
# EnvironmentFile=-/etc/default/%N; rke2 scans PATH for nvidia-container-runtime
# at service start only, and the RKE2 GPU docs say to set PATH there. The rke2
# install script does not touch /etc/default, so this survives the install.
# k3s has no env_file in %PATHS: its agent code does the same scan and wired a
# host toolkit plus the nvidia RuntimeClass on a DGX without help
# (kubernetes-ocp, _configure_nvidia_runtime_path).
sub _nvidia_runtime_path {
  my ($paths) = @_;
  my $env_file = $paths->{env_file} or return;

  unless (can_run('nvidia-container-runtime')) {
    Rex::Logger::info("nvidia-container-runtime not on PATH, $env_file left alone "
      . "(the GPU Operator's toolkit is found without it)");
    return;
  }

  my $current = run "cat $env_file 2>/dev/null", auto_die => 0;
  my $content = _env_with_runtime_path($? == 0 ? $current : '');
  unless (defined $content) {
    Rex::Logger::info("$env_file already carries the PATH for the NVIDIA runtime");
    return;
  }

  Rex::Logger::info("Writing PATH to $env_file for the NVIDIA runtime lookup");
  run "mkdir -p /etc/default", auto_die => 1;
  # No secret in here: the file keeps its mode, a new one gets root's umask.
  file $env_file, content => $content;

  # Only on a re-run: the service reads the file when it starts.
  my $service = $paths->{service};
  run "systemctl is-active --quiet $service", auto_die => 0;
  Rex::Logger::info("$service is running: restart it to pick up the new PATH", 'warn')
    if $? == 0;
}

# Pure: the env file with exactly one PATH line (ours, last), every other line
# kept in order. undef when the file already is exactly that.
sub _env_with_runtime_path {
  my ($current) = @_;
  $current //= '';
  my @keep = grep { !/^\s*PATH=/ } split /\n/, $current;
  my $content = join('', map { $_."\n" } @keep, $RUNTIME_PATH_LINE);
  return $content eq $current ? undef : $content;
}

#
# Wait until the kubeconfig file appears on the remote host.
# API readiness is checked locally by the caller via Rex::Rancher::K8s::wait_for_api.
#

sub _wait_for_kubeconfig {
  my ($paths) = @_;
  my $kubeconfig = $paths->{kubeconfig};

  Rex::Logger::info("Waiting for " . $paths->{service} . " to write kubeconfig...");

  for my $i (1..60) {
    my $out = run "test -f $kubeconfig && echo yes", auto_die => 0;
    if ($? == 0 && ($out // '') =~ /yes/) {
      Rex::Logger::info("  Kubeconfig ready at $kubeconfig");
      return 1;
    }
    Rex::Logger::info("  Not ready yet ($i/60), waiting...");
    sleep 5;
  }

  Rex::Logger::info($paths->{service} . " kubeconfig did not appear — check manually", "warn");
  return 0;
}

#
# Install method, release artifacts, version check, service wait.
# Shared with Rex::Rancher::Agent (same distributions, same artifacts).
#

sub _install_method {
  my ($method, $version) = @_;
  $method //= 'script';
  die "Unknown install_method: $method (expected 'script' or 'artifact')\n"
    unless $method eq 'script' || $method eq 'artifact';
  die "install_method 'artifact' requires a version (e.g. v1.30.4+rke2r1)\n"
    if $method eq 'artifact' && !$version;
  return $method;
}

# Release artifacts are named by GOARCH, not by `uname -m`.
sub _goarch {
  my ($uname) = @_;
  $uname //= '';
  $uname =~ s/\s+\z//;
  my %goarch = (
    x86_64  => 'amd64',
    amd64   => 'amd64',
    aarch64 => 'arm64',
    arm64   => 'arm64',
  );
  return $goarch{$uname}
    // die "Unsupported node architecture '$uname' for install_method 'artifact'"
    . " (amd64 and arm64 only)\n";
}

sub _artifact_spec {
  my ($distribution, $arch, $version) = @_;
  my $paths = _paths($distribution);

  die "install_method 'artifact' requires a version\n" unless $version;
  die "Invalid version '$version'\n" unless $version =~ /\A[A-Za-z0-9._+-]+\z/;

  (my $url_version = $version) =~ s/\+/%2B/g;
  my $base  = $paths->{release_url} . '/' . $url_version;
  my $dir   = $paths->{artifact_dir};
  my $asset = $distribution eq 'k3s'
    ? ($arch eq 'amd64' ? 'k3s' : "k3s-$arch")
    : "rke2.linux-$arch.tar.gz";
  my $sums  = "sha256sum-$arch.txt";

  return {
    dir        => $dir,
    script     => "$dir/install.sh",
    script_url => $paths->{install_url},
    asset      => $asset,
    asset_url  => "$base/$asset",
    sums       => $sums,
    sums_url   => "$base/$sums",
  };
}

# The line for exactly $asset in an official sha256sum-ARCH.txt, or undef.
# Exact name match: 'k3s' must not pick up 'k3s-airgap-images-...'.
sub _expected_sha256 {
  my ($sums_text, $asset) = @_;
  for my $line (split /\n/, $sums_text // '') {
    return lc $1 if $line =~ /\A\s*([0-9a-fA-F]{64})\s+\*?\Q$asset\E\s*\z/;
  }
  return;
}

# First field of `sha256sum FILE` output, or undef.
sub _sha256_of {
  my ($out) = @_;
  return lc $1 if ($out // '') =~ /\A\s*([0-9a-fA-F]{64})\b/;
  return;
}

sub _verify_sha256 {
  my ($expected, $actual, $asset) = @_;
  die "No checksum for $asset in the release's sha256sum file\n"
    unless defined $expected;
  die "Could not compute sha256 of downloaded $asset\n"
    unless defined $actual;
  die "Checksum mismatch for $asset: expected $expected, got $actual\n"
    unless $expected eq $actual;
  return 1;
}

sub _download_cmd {
  my ($url, $dest, $progress) = @_;
  # --progress-bar keeps output flowing during the ~60 MB tarball download,
  # so a long silent curl does not look like a hung channel.
  my $flags = $progress ? '-fL --progress-bar' : '-fsSL';
  return "curl $flags -o '$dest' '$url' 2>&1";
}

# Download install script, artifact and checksum file on the host (curl, no
# SFTP, no upload) and verify the artifact. Dies on any failure.
sub _fetch_artifacts {
  my ($distribution, $version) = @_;

  my $arch = _goarch(run "uname -m", auto_die => 1);
  my $spec = _artifact_spec($distribution, $arch, $version);
  my $dir  = $spec->{dir};

  Rex::Logger::info("Downloading $distribution $version artifacts for $arch to $dir");

  run "rm -rf '$dir' && mkdir -p '$dir'", auto_die => 1;

  for my $dl (
    [ $spec->{script_url}, $spec->{script},             0 ],
    [ $spec->{sums_url},   "$dir/$spec->{sums}",        0 ],
    [ $spec->{asset_url},  "$dir/$spec->{asset}",       1 ],
  ) {
    my ($url, $dest, $progress) = @{$dl};
    my $out = run _download_cmd($url, $dest, $progress), auto_die => 0;
    die "Download failed: $url\n"
      . ($progress ? "If this 404s, $distribution $version publishes no build for '$arch'.\n" : '')
      . ($out // '') . "\n"
      unless $? == 0;
  }

  my $sums   = run "cat '$dir/$spec->{sums}'", auto_die => 1;
  my $actual = run "sha256sum '$dir/$spec->{asset}'", auto_die => 1;
  # scalar(): both return empty on no match; in this list they must stay undef.
  _verify_sha256(scalar(_expected_sha256($sums, $spec->{asset})),
    scalar(_sha256_of($actual)), $spec->{asset});
  Rex::Logger::info("  $spec->{asset}: sha256 verified");

  return $spec;
}

# $type: undef for a server, 'agent' for an agent.
sub _rke2_artifact_install_cmd {
  my ($spec, $version, $type) = @_;
  my @env = ("INSTALL_RKE2_ARTIFACT_PATH=$spec->{dir}");
  push @env, "INSTALL_RKE2_TYPE=$type" if $type;
  push @env, "INSTALL_RKE2_VERSION=$version";
  return join(' ', @env) . " sh $spec->{script}";
}

# Put the verified binary where the K3s install script looks for it: next to
# it, then rename, so a running k3s ("text file busy") is replaced atomically.
sub _k3s_binary_place_cmd {
  my ($spec) = @_;
  return "install -m 0755 -o root -g root '$spec->{dir}/$spec->{asset}' /usr/local/bin/.k3s.rex-new"
    . " && mv -f /usr/local/bin/.k3s.rex-new /usr/local/bin/k3s";
}

# SKIP_DOWNLOAD=binary skips only the binary; the SELinux RPM on RHEL-likes is
# still fetched, as with curl | sh. BIN_DIR pinned to where we put the binary.
sub _k3s_artifact_install_cmd {
  my ($spec, $server, $version, $role) = @_;
  my @env;
  push @env, "K3S_URL=$server" if $server;
  push @env, 'INSTALL_K3S_SKIP_DOWNLOAD=binary', 'INSTALL_K3S_BIN_DIR=/usr/local/bin',
    "INSTALL_K3S_VERSION=$version";
  # No start from the script, server or agent: see _install_k3s.
  push @env, 'INSTALL_K3S_SKIP_START=true';
  my $cmd = join(' ', @env) . " sh $spec->{script} $role";
  $cmd .= ' --write-kubeconfig-mode=644' if $role eq 'server';
  return $cmd;
}

# "rke2 version v1.30.4+rke2r1 (abc)" / "k3s version v1.30.4+k3s1 (abc)"
sub _parse_version_output {
  my ($out) = @_;
  return $1 if ($out // '') =~ /^(?:rke2|k3s) version (\S+)/m;
  return;
}

sub _same_version {
  my ($want, $got) = @_;
  return 0 unless defined $want && defined $got;
  my ($w, $g) = ($want, $got);
  s/\Av// for $w, $g;
  return $w eq $g ? 1 : 0;
}

sub _verify_installed_version {
  my ($distribution, $version) = @_;
  return 1 unless $version;

  my $binary = _paths($distribution)->{binary};
  my $out    = run "$binary --version 2>&1", auto_die => 0;
  my $got    = _parse_version_output($out);
  die "Could not determine installed $distribution version ($binary --version):\n"
    . ($out // '') . "\n"
    unless defined $got;
  die "Installed $distribution version is $got, expected $version — the "
    . "install or upgrade did not take effect\n"
    unless _same_version($version, $got);
  Rex::Logger::info("  $distribution $got installed");
  return 1;
}

# Poll `systemctl is-active` until active. 'failed' dies at once; any other
# state (activating, inactive right after --no-block, auto-restart loops)
# is polled until the timeout. Either failure carries the journal tail.
sub _wait_for_service {
  my ($service, %args) = @_;
  my $attempts = $args{attempts} // 60;
  my $interval = $args{interval} // 10;

  Rex::Logger::info("Waiting for $service to become active...");

  my $state = '';
  for my $i (1 .. $attempts) {
    $state = run "systemctl is-active $service", auto_die => 0;
    $state = '' unless defined $state;
    $state =~ s/\s+\z//;
    if ($state eq 'active') {
      Rex::Logger::info("  $service is active");
      return 1;
    }
    die _service_failure($service, "is failed") if $state eq 'failed';
    Rex::Logger::info("  $service is " . ($state || 'unknown') . " ($i/$attempts)");
    sleep $interval if $i < $attempts;
  }

  die _service_failure($service,
    "did not become active within " . ($attempts * $interval) . "s (last state: "
      . ($state || 'unknown') . ")");
}

sub _service_failure {
  my ($service, $reason) = @_;
  my $journal = run "journalctl -u $service -n 50 --no-pager 2>&1", auto_die => 0;
  $journal = '' unless defined $journal;
  $journal =~ s/\s+\z//;
  return "$service $reason\n"
    . "--- journalctl -u $service -n 50 ---\n"
    . ($journal eq '' ? '(no journal output)' : $journal) . "\n";
}

sub _generate_registries_yaml {
  my ($config_dir, $registries) = @_;

  my $registries_file = $config_dir . "registries.yaml";
  Rex::Logger::info("Writing registries config to $registries_file");

  _write_secret_file($registries_file,
    YAML::PP->new(boolean => 'JSON::PP')->dump_string($registries));
}

# config.yaml carries the join token and registries.yaml may carry registry
# passwords, so both end up 0600 root:root. Rex's `file` writes content to a
# ".rex.tmp.<name>" sibling (LibSSH: `cat >` over an exec channel, no SFTP),
# renames it over the target and only then chmods -- the tmp file would be
# umask-mode (0644) in between. Pre-creating that tmp name at 0600 closes the
# window: `cat >` and SFTP open-truncate both keep an existing inode's mode,
# and the rename carries it to the target. The explicit chmod afterwards is
# what fixes an existing 0644 file whose content is unchanged (Rex then drops
# the tmp file and never touches the target), and fails loudly.
sub _write_secret_file {
  my ($path, $content) = @_;

  my $tmp = Rex::Commands::File::get_tmp_file_name($path);
  run "install -m 600 -o root -g root /dev/null $tmp", auto_die => 1;

  file $path, content => $content;

  run "chown root:root $path && chmod 600 $path", auto_die => 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Server - Rancher Kubernetes server (control plane) installation

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Rex::Rancher::Server;

  # Install RKE2 server (default)
  install_server(
    token   => 'my-cluster-secret',
    tls_san => ['lb.example.com'],
  );

  # Install K3s server
  install_server(
    distribution => 'k3s',
    token        => 'my-cluster-secret',
    tls_san      => ['lb.example.com'],
  );

  # Join additional control plane node (HA setup)
  install_server(
    distribution => 'rke2',
    token        => 'my-cluster-secret',
    server       => 'https://first-server:9345',
  );

  # Retrieve kubeconfig and join token from a running server
  my $kubeconfig = get_kubeconfig('rke2');
  my $token      = get_token('rke2');

  # Update registry mirrors on an already-running node
  update_registries(
    distribution => 'rke2',
    registries   => {
      mirrors => { 'docker.io' => { endpoint => ['http://cache:5000'] } },
    },
  );

=head1 DESCRIPTION

L<Rex::Rancher::Server> handles control plane installation for both RKE2
and K3s Kubernetes distributions. It provides a unified interface for
installing, configuring, and managing server nodes.

=head2 RKE2 installation

By default the official install script at L<https://get.rke2.io> is fetched
and run via C<curl -sfL … | sh ->; with C<install_method =E<gt> 'artifact'>
the checksum-verified release tarball is installed instead (see
L</install_server>). The service is started with C<--no-block> to avoid
systemd's 90-second activation timeout (RKE2's first start pulls many
container images), then polled with C<systemctl is-active> for up to 10
minutes; a C<failed> or never-active service dies with its journal tail.
After that the function waits until the kubeconfig file appears at
C</etc/rancher/rke2/rke2.yaml>; API readiness is confirmed separately by the
caller using L<Rex::Rancher::K8s/wait_for_api>.

=head2 K3s installation

The official install script at L<https://get.k3s.io> is used (piped, or run
against the checksum-verified binary with C<install_method =E<gt>
'artifact'>), with C<K3S_URL> set when joining an existing server. The
script runs with C<INSTALL_K3S_SKIP_START>: instead of its own blocking
restart, C<k3s.service> is restarted with C<--no-block>, then the same
C<systemctl is-active> wait (at most 10 minutes, journal tail on failure) as
for RKE2 follows, so a joining server that cannot reach the first one dies
instead of hanging the deploy. Then the kubeconfig wait. The token is read from
C<config.yaml> and never passed on the command line. Traefik and
ServiceLB are disabled by default (C<disable> in C<config.yaml>, see
L</install_server>) to leave room for Cilium and external load balancers.

=head2 Config layout

Both distributions use C</etc/rancher/E<lt>distE<gt>/config.yaml> with the
same key names (C<token>, C<tls-san>, C<node-name>, C<node-label>,
C<disable>, C<cni>, etc.). When
C<cilium =E<gt> 1> (the default), the distribution's own CNI is switched off
so that Cilium is the only one: on RKE2 C<cni: none> and
C<disable-kube-proxy: true>, on K3s C<flannel-backend: none>,
C<disable-network-policy: true>, C<disable-kube-proxy: true> and
C<cluster-cidr: 10.42.0.0/16>; on both, Cilium's kube-proxy replacement takes
over. See L</install_server>'s C<cilium>.

Registry mirrors are written to C<registries.yaml> in the same directory.
Both files are C<0600 root:root>: C<config.yaml> holds the join token,
C<registries.yaml> may hold registry credentials.

=head1 FUNCTIONS

=head2 install_server(%opts)

Write the cluster configuration file, optionally write C<registries.yaml>,
install the distribution, start the service, wait until C<systemctl
is-active> reports it active, and then wait until the kubeconfig file is
written to disk by the server process.

Returns C<1> on success. Dies if installation fails, the distribution is
unknown, the installed version differs from a pinned C<version>, or the
service does not become active within 10 minutes. A service that ends up
C<failed> or never gets active makes the C<die> message carry the last 50
lines of its journal (C<journalctl -u SERVICE -n 50 --no-pager>).

Options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>. B<rke2 is the verified distribution.> The k3s
path carries the configuration kubernetes-ocp verified live (see L</cilium>),
but has not itself been run live through Rex::Rancher.

=item C<token>

Shared secret used for node joining. If omitted, the token the server is
already sealed with (C</var/lib/rancher/rke2/server/token>, K3s:
C</var/lib/rancher/k3s/server/token>) is reused, so re-running
C<install_server> on a live control plane never rotates its token. Only on a
fresh server (no such file) is a new one generated (up to 48 random
alphanumeric characters, never fewer than 32).
A passed C<token> always wins.

The token is written to C<config.yaml> only; it is never put on the installer
command line or into its environment, where C<ps> would show it. C<config.yaml>
is written C<0600 root:root>, including when it already exists.

=item C<server>

URL of an existing server node to join. Used for multi-server HA setups
(omit for the first/only server). For RKE2 the port is C<9345>; for K3s it
is C<6443>.

=item C<tls_san>

Additional TLS Subject Alternative Names for the API server certificate,
as an arrayref or a comma-separated string. Include the load balancer
address, public IP, or DNS name so that kubeconfig clients can connect.

=item C<version>

Pinned version string, e.g. C<v1.30.4+rke2r1> for RKE2 or C<v1.30.4+k3s1>
for K3s, handed to the installer as C<INSTALL_RKE2_VERSION> /
C<INSTALL_K3S_VERSION>. If omitted, the latest stable release is installed.

When given, the version the installed binary reports (C<rke2 --version> /
C<k3s --version>) is compared with it after the installer ran, and a
mismatch dies (on RKE2 before the service is started; the K3s install
script has already restarted it). This catches a pinned
install or upgrade that failed while an older binary is still on the host.

=item C<install_method>

How the distribution gets onto the host. C<script> (default) pipes the
official install script into C<sh> (C<curl -sfL https://get.rke2.io | sh ->,
K3s: C<https://get.k3s.io>), exactly as without this option.

C<artifact> pre-downloads the release artifact for the node's own
architecture (C<uname -m> on the host: C<amd64> or C<arm64>, anything else
dies) from the GitHub release, verifies it against the release's official
C<sha256sum-ARCH.txt> and dies loudly on a mismatch, then runs the install
script against the local file: RKE2 via C<INSTALL_RKE2_ARTIFACT_PATH>
(tarball C<rke2.linux-ARCH.tar.gz>), K3s by installing the binary to
C</usr/local/bin/k3s> and running the script with
C<INSTALL_K3S_SKIP_DOWNLOAD=binary>. Downloads run on the host with C<curl>
(no SFTP, nothing is uploaded) into C</tmp/rke2-artifacts> /
C</tmp/k3s-artifacts>, which are emptied first. Requires C<version>; dies
without one.

On RPM-based hosts (Rocky, RHEL) RKE2's install script uses the tarball
instead of its RPM method when given an artifact path, so no C<rke2-selinux>
package is installed, and a host that already carries RKE2 from RPMs is
refused by the script ("existing RKE2 RPMs").

=item C<node_name>

Kubernetes node name, written as C<node-name> to C<config.yaml>. If omitted,
the system hostname is used.

=item C<disable>

Packaged components to switch off, as an arrayref or a comma-separated
string, written as C<disable> to C<config.yaml>. The names are
distribution-specific. Default: C<['rke2-ingress-nginx', 'rke2-traefik',
'rke2-traefik-crd']> on rke2 (no bundled ingress controller: RKE2 ships the
Traefik charts since v1.30.3, opt-in, and deploys Traefik by default on new
clusters since v1.36; a name the installed RKE2 does not ship is ignored),
C<['traefik', 'servicelb']> on k3s. A given list replaces the default rather
than extending it; C<[]> disables nothing. Independent of C<cilium>.

  # keep the default and also drop metrics-server
  disable => [qw( rke2-ingress-nginx rke2-traefik rke2-traefik-crd
                  rke2-metrics-server )],

=item C<node_labels>

Node labels applied at join time, as an arrayref of C<key=value> strings.

=item C<registries>

Private registry mirror configuration. Written to C<registries.yaml> in the
distribution config directory, C<0600 root:root>
(it may hold registry passwords). Structure:

  {
    mirrors => {
      'docker.io' => { endpoint => ['http://registry.internal:5000'] },
    },
    configs => {
      'registry.internal:5000' => {
        auth => { username => 'user', password => 'pass' },
      },
    },
  }

=item C<cilium>

If true (default: C<1>), switch off the distribution's own CNI in the
server config so that Cilium is the only one. Set to C<0> to keep the
distribution's default CNI (Canal on RKE2, Flannel on K3s).

On B<rke2>, C<cni: none> and C<disable-kube-proxy: true> are written,
preparing the node for Cilium with full kube-proxy replacement.

On B<k3s>, C<flannel-backend: none>, C<disable-network-policy: true>,
C<disable-kube-proxy: true> and C<cluster-cidr: 10.42.0.0/16> are written:
Flannel, k3s's embedded network policy controller and kube-proxy are
switched off, and Cilium takes over all three with kube-proxy replacement.
C<cluster-cidr> is k3s's own default, written out because Cilium's
cluster-pool IPAM is given the same range (see L<Rex::Rancher::Cilium>). These
are server settings that k3s agents take from the server; an additional
server joining with C<server> gets the same keys, as k3s requires them to
match across servers. The same keys and Cilium values were verified live in
kubernetes-ocp (k3s v1.36.4+k3s1, Cilium 1.20.0, Gateway API v1.6.1); the
k3s path through Rex::Rancher has not been run live, and differs in the
Cilium version it defaults to (see L<Rex::Rancher::Cilium>).

=item C<nvidia_runtime_path>

If true, and C<nvidia-container-runtime> is on the host's C<PATH>, write
C<PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin> to
C</etc/default/rke2-server> before the installer runs. The rke2 unit sets no
C<PATH>, and rke2 looks for the NVIDIA runtime only when the service starts;
without it a host- or vendor-installed toolkit (C</usr/bin>, e.g. DGX OS) is
not wired into containerd. Other lines of the file are kept, an existing
C<PATH=> line is replaced. If the file changed while the service is already
running, a warning asks for a restart; nothing is restarted. The GPU
Operator's toolkit (C</usr/local/nvidia/toolkit>) is found by rke2 without
this. No effect on k3s. Default: C<0>; L<Rex::Rancher/rancher_deploy_server>
turns it on for C<gpu =E<gt> 1, gpu_setup =E<gt> 0>.

=back

  install_server(
    distribution => 'rke2',
    token        => 'my-cluster-secret',
    tls_san      => ['loadbalancer.example.com'],
    node_labels  => ['role=control-plane'],
    version      => 'v1.30.4+rke2r1',
    node_name    => 'cp-01',
  );

  # Checksum-verified release artifact instead of curl | sh
  install_server(
    version        => 'v1.30.4+rke2r1',
    install_method => 'artifact',
  );

=head2 update_registries(%opts)

Update C<registries.yaml> on an already-running node and restart the
distribution service to pick up the new registry mirror configuration.

Use this to add or change registry mirrors after the cluster is up — for
example, after deploying an in-cluster registry that you want every node
to use as a pull-through cache.

Required options:

=over

=item C<registries>

Registry mirror hashref (same structure as C<install_server>'s C<registries>
option).

=back

Optional options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>. Controls which service is restarted.

=back

  update_registries(
    distribution => 'rke2',
    registries   => {
      mirrors => {
        'docker.io'         => { endpoint => ['http://registry.internal:5000'] },
        'registry.internal' => { endpoint => ['http://registry.internal:5000'] },
      },
    },
  );

=head2 get_kubeconfig($distribution)

Read the kubeconfig file from the remote server and return its content as
a string. The file is read directly via C<cat> over SSH; no SFTP is used.

C<$distribution> defaults to C<rke2>.

Note: RKE2 and K3s both write C<https://127.0.0.1> as the server address.
The caller is responsible for substituting the real server address before
saving the kubeconfig for external use. L<Rex::Rancher/rancher_deploy_server>
performs this substitution automatically.

Dies if the file cannot be read.

=head2 get_token($distribution)

Read the node join token from the server and return it as a string
(trailing newline stripped).

C<$distribution> defaults to C<rke2>.

The token is stored at:

=over

=item RKE2: C</var/lib/rancher/rke2/server/node-token>

=item K3s: C</var/lib/rancher/k3s/server/node-token>

=back

Dies if the file cannot be read (e.g. server not yet started).

=head1 SEE ALSO

L<Rex::Rancher>, L<Rex::Rancher::Node>, L<Rex::Rancher::Agent>,
L<Rex::Rancher::Cilium>, L<Rex::Rancher::K8s>, L<Rex>

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
