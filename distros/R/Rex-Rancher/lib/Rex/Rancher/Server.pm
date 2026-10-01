# ABSTRACT: Rancher Kubernetes server (control plane) installation

package Rex::Rancher::Server;
our $VERSION = '0.003';
use v5.14.4;
use warnings;

use Fcntl qw( O_CREAT O_TRUNC O_WRONLY );
use Rex::Commands::File;
use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Logger;
use Rex::Rancher::Distribution;
use Rex::Rancher::Options;
use Rex::Rancher::Uninstall ();
use Socket qw( AF_INET6 inet_pton );
use YAML::PP;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_server
  update_registries
  get_kubeconfig
  fetch_kubeconfig
  patch_kubeconfig_server
  get_token
);



sub install_server {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $dist         = Rex::Rancher::Distribution->new_for($distribution);
  Rex::Logger::info(
    "$distribution has not been run live through Rex::Rancher; rke2 is the "
      . "verified distribution.", "warn")
    unless $dist->live_verified;
  # Everything that may refuse, before anything is written (the token lookup
  # below is the first read after it); rancher_deploy_server asked the same
  # before it prepared the node (k78).
  my $checked      = preflight_server(%opts);
  my $method       = $checked->{install_method};
  my $cluster_cidr = $checked->{cluster_cidr};
  my $version      = $checked->{version};
  my $hold         = $opts{hold_running};
  my $cilium       = exists $opts{cilium} ? $opts{cilium} : 1;
  my $token        = _resolve_token($dist, $opts{token});
  my $server       = $opts{server};
  my $tls_san      = $opts{tls_san};
  my $node_labels  = $opts{node_labels};
  my $registries   = $opts{registries};
  my $node_name    = $opts{node_name};
  my $disable      = $opts{disable};

  Rex::Logger::info("Installing $distribution server (control plane)...");

  # Ensure config directory exists
  file $dist->config_dir . '/', ensure => 'directory';

  # Write config.yaml
  _write_config($dist, $token, $server, $tls_san, $node_labels, $cilium,
    $node_name, $disable, $cluster_cidr);

  # Write registries.yaml if configured
  if ($registries) {
    $dist->write_registries($registries);
  }

  # Before the installer: rke2 looks for the NVIDIA runtime only when its
  # service starts.
  $dist->ensure_nvidia_runtime_path if $opts{nvidia_runtime_path};

  # Install and start
  _install($dist, $server, $version, $method, $hold);

  Rex::Logger::info("$distribution server installation complete");

  return 1;
}


sub preflight_server {
  my (%opts) = @_;
  my $dist = Rex::Rancher::Distribution->new_for($opts{distribution});

  # Pure, before anything touches the host. scalar(): no cluster_cidr
  # returns an empty list, which would shift the pairs here.
  my %checked = (
    install_method => scalar Rex::Rancher::Options->resolve_install_method($opts{install_method}, $opts{version}),
    cluster_cidr   => scalar Rex::Rancher::Options->check_cluster_cidr($opts{cluster_cidr}),
  );
  # The first read of the host: Cilium state an earlier cluster left on a host
  # without RKE2/K3s would hang every image pull of this install (k71).
  Rex::Rancher::Uninstall->check_cilium_residue;
  # hold_running: the version on the host is this run's version, for the
  # skew check and everything after it (k77).
  $checked{version} = $opts{hold_running}
    ? $dist->held_version(version => $opts{version}) : $opts{version};
  # A rejected upgrade leaves the host as it was.
  $dist->check_version_skew(version => $checked{version});
  # Nor another pod network for a server already set up here: config.yaml
  # would carry it and the service be restarted onto it (k67).
  $dist->check_established_cluster_cidr(cluster_cidr => $checked{cluster_cidr},
    cilium => ( exists $opts{cilium} ? $opts{cilium} : 1 ));
  return \%checked;
}


sub update_registries {
  my (%opts) = @_;

  my $distribution = $opts{distribution} // 'rke2';
  my $registries   = $opts{registries} or die "update_registries requires 'registries' option\n";
  my $dist         = Rex::Rancher::Distribution->new_for($distribution);

  Rex::Logger::info("Updating registries.yaml for $distribution");

  $dist->write_registries($registries);

  # Before the restart: it would render Rex::GPU 0.001's bare containerd
  # template again, which carries no registry mirrors. Dies if it cannot.
  $dist->remove_bare_containerd_template;

  # Restart containerd to pick up new config: whichever unit this node runs.
  run $dist->restart_services_cmd, auto_die => 0;

  Rex::Logger::info("Registries updated, containerd restarted");
}


sub get_kubeconfig {
  my ($distribution) = @_;
  my $dist = Rex::Rancher::Distribution->new_for($distribution);

  Rex::Logger::info("Retrieving kubeconfig from " . $dist->kubeconfig);

  my $content = run "cat " . $dist->kubeconfig, auto_die => 1;
  return $content;
}


sub fetch_kubeconfig {
  my (%opts) = @_;
  my $server = $opts{server};
  my $filter = $opts{filter};
  my $file   = $opts{file};

  die "fetch_kubeconfig: filter must be a code reference\n"
    if defined $filter && ref $filter ne 'CODE';
  my $dist = Rex::Rancher::Distribution->new_for($opts{distribution});

  my $content = eval { get_kubeconfig($dist->name) };
  unless ($content) {
    my $err = $@ ? $@ =~ s/\s+\z//r : 'empty file';
    die "Could not fetch the kubeconfig from the " . $dist->name
      . " server ($err)\n";
  }

  $content = patch_kubeconfig_server($content, $server)
    if defined $server && length $server;

  if ($filter) {
    $content = $filter->($content);
    die "fetch_kubeconfig: filter returned no kubeconfig, nothing was written\n"
      unless defined $content && length $content;
  }

  if (defined $file && length $file) {
    _write_kubeconfig($file, $content);
    Rex::Logger::info("Kubeconfig saved to $file");
  }

  return $content;
}


sub patch_kubeconfig_server {
  my ( $content, $server ) = @_;
  die "patch_kubeconfig_server: no kubeconfig given\n" unless defined $content;
  die "patch_kubeconfig_server: no server address given\n"
    unless defined $server && length $server;

  $server = '' . $server;    # a Rex server object names its host when stringified
  $server = '[' . $server . ']' if defined inet_pton(AF_INET6, $server);
  $content =~ s{https://(?:127\.0\.0\.1|\[::1\]):(\d+)}{https://$server:$1}g;
  return $content;
}

# The admin client certificate and key are in there: created 0600, and an
# existing file (older versions wrote it umask-mode) narrowed before the
# content goes in. In place, not rename, so a symlinked path keeps its link.
# A local file: CORE::chmod, because the chmod Rex::Commands::Fs exports into
# this package runs on the remote host.
sub _write_kubeconfig {
  my ( $file, $content ) = @_;
  my $fail = sub { die "Could not write the kubeconfig to $file: $!\n" };

  sysopen(my $fh, $file, O_WRONLY | O_CREAT | O_TRUNC, 0600) or $fail->();
  CORE::chmod(0600, $file) or $fail->();
  print {$fh} $content or $fail->();
  close $fh or $fail->();
  return;
}


sub get_token {
  my ($distribution) = @_;
  my $dist = Rex::Rancher::Distribution->new_for($distribution);

  Rex::Logger::info("Retrieving node token from " . $dist->token_file);

  my $content = run "cat " . $dist->token_file, auto_die => 1;
  chomp $content;
  return $content;
}

# Never rotate the token a control plane is already sealed with: the datastore
# encryption key derives from it at bootstrap and is only re-checked at the
# NEXT start, so a fresh token in config.yaml arms a fatal "bootstrap data
# already found and encrypted with different token" on the next restart.
sub _resolve_token {
  my ($dist, $given) = @_;
  return $given if defined $given;
  my $existing = _existing_server_token($dist);
  if (defined $existing) {
    Rex::Logger::info("Reusing existing cluster token from " . $dist->server_token);
    return $existing;
  }
  return _generate_token();
}

# Read over the exec channel (no SFTP). A missing or unreadable file means
# "fresh server" and degrades to undef; it must never abort the install.
sub _existing_server_token {
  my ($dist) = @_;
  my $out = run "cat " . $dist->server_token . " 2>/dev/null", auto_die => 0;
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
  my ($dist, $token, $server, $tls_san, $node_labels, $cilium,
    $node_name, $disable, $cluster_cidr) = @_;

  my %config = (
    'token' => $token,
  );

  # With cilium, Cilium is the only CNI and replaces kube-proxy on both
  # distributions (Rex::Rancher::Cilium wires kubeProxyReplacement); which
  # keys that takes is the distribution's cilium_config.
  %config = ( %config, %{ $dist->cilium_config } ) if $cilium;

  # A given cluster_cidr is written on both distributions, with or without
  # cilium; every server of a cluster must carry the same one (RKE2 refuses
  # a join that differs). Without it rke2 keeps its own default, unwritten.
  $config{'cluster-cidr'} = $cluster_cidr if defined $cluster_cidr;

  # Packaged components to switch off. Undef means the distribution's
  # default_disable (rke2: ingress-nginx + traefik charts, unknown chart
  # names are ignored by RKE2; k3s: traefik + servicelb). An explicit empty
  # list disables nothing. Independent of cilium.
  my @disable = !defined $disable       ? @{ $dist->default_disable }
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
  my ($dist, $token, $server, $tls_san, $node_labels, $cilium,
    $node_name, $disable, $cluster_cidr) = @_;

  my $config =
    _build_server_config($dist, $token, $server, $tls_san, $node_labels, $cilium,
      $node_name, $disable, $cluster_cidr);

  my $config_file = $dist->config_file;
  Rex::Logger::info("Writing config to $config_file");

  $dist->write_secret_file($config_file,
    YAML::PP->new(boolean => 'JSON::PP')->dump_string($config));
}

#
# Install and start. Server and agent share the steps in
# Rex::Rancher::Distribution; what differs between rke2 and k3s is there too.
#

sub _install {
  my ($dist, $server, $version, $method, $hold) = @_;

  # Held, k3s is restarted only for a change: its installer rewrites the
  # unit and env file on every run, so their content is compared (start_verb).
  my $units = $hold ? $dist->installer_unit_digest : undef;
  # No token on any installer line: it is already in config.yaml (written
  # before the installer runs), and anything on these lines shows up in ps.
  $dist->install_server_package($server, $version, $method);
  # The binary being there is not enough when a version is pinned: a failed
  # pinned upgrade leaves the old one in place.
  $dist->verify_installed_version($version);
  # Before the start decision: this start would render Rex::GPU 0.001's bare
  # containerd template again (start_verb restarts a running service whose
  # config.toml is still its output).
  $dist->remove_bare_containerd_template;

  # Enable and start the service. --no-block: return immediately; RKE2 first
  # start pulls many images and exceeds systemctl's default 90s activation
  # timeout, and k3s' Type=notify unit blocks until k3s is up, forever for
  # an HA join that cannot reach its first server. Start or restart as the
  # distribution wants it (start_verb), then the bounded wait.
  my $service = $dist->service;
  run "systemctl enable " . $service, auto_die => 1;
  run "systemctl " . $dist->start_verb(pinned => ( defined $version && length $version ),
      hold => $hold, unit_digest => $units)
    . " --no-block " . $service, auto_die => 1;

  $dist->wait_for_service;

  # Then wait until kubeconfig is written — API readiness is checked locally
  # by the caller via Rex::Rancher::K8s::wait_for_api after saving the file.
  _wait_for_kubeconfig($dist);
}

#
# Wait until the kubeconfig file appears on the remote host.
# API readiness is checked locally by the caller via Rex::Rancher::K8s::wait_for_api.
#

sub _wait_for_kubeconfig {
  my ($dist) = @_;
  my $kubeconfig = $dist->kubeconfig;

  Rex::Logger::info("Waiting for " . $dist->service . " to write kubeconfig...");

  for my $i (1..60) {
    my $out = run "test -f $kubeconfig && echo yes", auto_die => 0;
    if ($? == 0 && ($out // '') =~ /yes/) {
      Rex::Logger::info("  Kubeconfig ready at $kubeconfig");
      return 1;
    }
    Rex::Logger::info("  Not ready yet ($i/60), waiting...");
    sleep 5;
  }

  Rex::Logger::info($dist->service . " kubeconfig did not appear — check manually", "warn");
  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Server - Rancher Kubernetes server (control plane) installation

=head1 VERSION

version 0.003

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

  # The kubeconfig for this machine: pointed at the server's address, saved 0600
  fetch_kubeconfig(
    distribution => 'rke2',
    server       => 'lb.example.com',
    file         => "$ENV{HOME}/.kube/cluster.yaml",
  );

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
A running C<rke2-server> is left running on a re-run (C<systemctl start>)
unless it has to take something new (see L</Re-runs>). Before the service
is (re)started, an C<agent/etc/containerd/config.toml.tmpl> that holds only
C<imports> and C<version = 2>, as L<Rex::GPU> 0.001 wrote it, is removed with
a warning: rke2 renders it instead of its own containerd config, so no
C<SystemdCgroup>, sandbox image or registry mirrors. The content decides,
never the path: any other template stays, with a log line. If the removal
fails, C<install_server> dies before the start. While
C<agent/etc/containerd/config.toml> is still that template's output, a
running service is then restarted once, with a warning, so rke2 renders its
own containerd config (see
L<Rex::Rancher::Distribution/remove_bare_containerd_template>). K3s is
restarted on every run anyway (below), so it renders its config either way.
After that the function waits until the kubeconfig file appears at
C</etc/rancher/rke2/rke2.yaml>; API readiness is confirmed separately by the
caller using L<Rex::Rancher::K8s/wait_for_api>.

=head2 Re-runs

A running RKE2 reads its configuration only when it starts, so
C<install_server> (and L<Rex::Rancher::Agent/install_agent> for
C<rke2-agent>) restarts a running service with C<--no-block>, logging why,
when the host has changed under it since its main process started:

=over

=item * C<config.yaml>, C<config.yaml.d/>, C<registries.yaml> or
C</etc/default/rke2-server> (C<-agent>) modified, or a containerd
C<config.toml.tmpl>, C<config-v3.toml.tmpl> or C<config-v3.toml.d/> drop-in
(as L<Rex::GPU> writes) — by modification time, and Rex rewrites a file only
when its content differs, so the same options twice change nothing. An
upgraded C<nvidia-container-runtime> alone is no reason, containerd runs it
anew per container;

=item * an installed C<rke2> binary of another version than the running one,
where the version skew policy lets it be restarted: a patch release, or the
next minor with C<version> pinned.

=back

Before any of that, the installed binary is compared with the running one
(RKE2 and K3s): the next minor without a pinned C<version> is not restarted
onto, with a warning, and a jump of more than one minor or a downgrade
(possible only when the stable channel could not be resolved before the
install, or moved in between) dies without a restart. See C<version> under
L</install_server>.

Nothing changed: C<systemctl start>, the service keeps running. Changes
made by hand or left by an interrupted earlier run count as well. What
cannot be determined (no C<ps>) counts as unchanged, with a warning. Details
in L<Rex::Rancher::Distribution/restart_reasons>.

A restart takes this server's API and etcd member down for its duration and
touches no other node. Several servers of one HA cluster restarting at the
same time can lose etcd quorum: deploy them one after another (Rex's
default), not in parallel. K3s is restarted on every run, as its install
script rewrites the unit each time, except onto an unpinned new minor, and
except with C<hold_running>: then it is restarted as RKE2 is, and also when
the install script changed the content of its unit or env file (see
C<hold_running> under L</install_server>).

=head2 K3s installation

The official install script at L<https://get.k3s.io> is used (piped, or run
against the checksum-verified binary with C<install_method =E<gt>
'artifact'>), with C<K3S_URL> set when joining an existing server. The
script runs with C<INSTALL_K3S_SKIP_START>: instead of its own blocking
restart, C<k3s.service> is restarted with C<--no-block>, then the same
C<systemctl is-active> wait (at most 10 minutes, journal tail on failure) as
for RKE2 follows, so a joining server that cannot reach the first one dies
instead of hanging the deploy. A bare C<config.toml.tmpl> in
C</var/lib/rancher/k3s/agent/etc/containerd> is removed before that
restart, as on RKE2. Then the kubeconfig wait. The token is read from
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
unknown, the host carries Cilium datapath state from an earlier cluster but
no RKE2 or K3s (see below), the installed version differs from a pinned
C<version>, a server already set up on the host would get another
C<cluster-cidr> (see L</cluster_cidr>), or the service does not become
active within 10 minutes. A service that ends up C<failed> or never gets
active makes the C<die> message carry the last 50 lines of its journal
(C<journalctl -u SERVICE -n 50 --no-pager>).

The first thing read from the host, before anything is written or
installed, is whether an earlier cluster left Cilium's datapath behind:
the pins in C</sys/fs/bpf/cilium>, the C</run/cilium/cgroupv2> mount or the
C<cilium_host> device, on a host with neither RKE2 nor K3s (no C<rke2> or
C<k3s> on C<PATH>, none of their server and agent units active). The vendor
uninstall scripts leave that state until a reboot, and its socket load
balancer makes connections to the old cluster's service addresses hang, so
every image pull of the new install stalls on a registry mirror among them.
Such a host dies naming what was found and asking for a reboot; see
L<Rex::Rancher::Uninstall/check_cilium_residue>. With RKE2 or K3s on the
host the state is its running cluster's (a re-run, an upgrade) and is not
checked.

Options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>. Both have been run live through Rex::Rancher;
what the k3s runs covered is listed in L<Rex::Rancher::Distribution::K3s>.

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
mismatch dies before the service is started, on RKE2 and K3s alike (the
K3s install script runs with C<INSTALL_K3S_SKIP_START>). This catches a pinned
install or upgrade that failed while an older binary is still on the host.

Against a running server the version skew policy applies, for RKE2 and K3s
alike, before anything is written or installed: a version more than one
minor ahead of the running one, or older than it, dies with both versions
and the host unchanged. Without C<version> the version checked is the one
the install script would take from the stable channel
(C<https://update.rke2.io/v1-release/channels/stable>, K3s:
C<update.k3s.io>), resolved on the host with C<curl>; if that fails, a
warning, and the check happens after the install instead, before any
restart (see L</Re-runs>). A patch release of the running minor is
installed and the service restarted, pinned or not. The next minor restarts
it only when C<version> is pinned; unpinned, it is installed but the running
server is B<not> restarted and keeps its old version until its next start
(a reboot), with a warning that says so and names
C<systemctl restart SERVICE>. Upgrade a cluster server by server, one minor
at a time, then the agents.

A server that is not running (stopped, crashed, never started) is held to
the same rules against the installed binary (C<rke2 --version> /
C<k3s --version>), the version it would start on: a jump or a downgrade dies
before anything is installed, and the next minor without C<version> is
installed with a warning, since nothing holds a stopped service back from
starting on it. No binary on the host is a fresh install and is not
checked. If the stable channel cannot be resolved there, only a warning
says the skew is not checked.

=item C<hold_running>

If true, the host stays on the version it runs: the version of the running
server (its main process, C</proc/PID/exe --version>) is this run's
C<version>, for the version skew check, the installer, the check of the
installed version and the restart decision alike. A server that is not
running holds the installed binary's version (C<rke2 --version> /
C<k3s --version>); with neither, C<version> applies, and without it the
stable channel, as without C<hold_running>. A running server whose version
cannot be read holds the installed binary instead, and without one
C<version>, each with a warning. It is read before anything is written or
installed, RKE2 and K3s alike (see
L<Rex::Rancher::Distribution/held_version>).

A C<version> given as well is installed only where there is nothing to
hold; otherwise the held version wins, and a warning names both.
C<install_method =E<gt> 'artifact'> still requires C<version>, for a host
with nothing to hold.

Held, the server is restarted only when its configuration changed (see
L</Re-runs>; the binary stays on the version it runs): RKE2 as without
C<hold_running>, and K3s, which is otherwise restarted on every run, the same
way, and also when the install script wrote C</etc/systemd/system/k3s.service>
or C<k3s.service.env> with other content than before, the check the K3s
install script itself makes before it restarts K3s. Default: C<0>.

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

=item C<cluster_cidr>

The pod network, one IPv4 CIDR such as C<10.42.0.0/16>, written as
C<cluster-cidr> to C<config.yaml> on RKE2 and K3s alike, with or without
C<cilium>. Anything else (including a dual-stack list) dies before the host
is touched. Every server of a cluster needs the same value (RKE2 refuses a
joining server that differs), and it cannot be changed on a running cluster.
L<Rex::Rancher::Cilium/install_cilium> takes the same value as Cilium's
pool, used in C<cluster-pool> mode (see there). Default: nothing written on
RKE2 (RKE2's own default, C<10.42.0.0/16>, applies); on K3s with C<cilium>
C<10.42.0.0/16> is written, without it nothing.

On a server already set up on the host (its service active, or
C<server/token> there), RKE2 and K3s alike, the value it runs with is read
first: C<cluster-cidr> from C<config.yaml> and its C<config.yaml.d/> drop-ins,
merged as the distribution merges them (the last one wins), or without one
the built-in C<10.42.0.0/16>. When this run would give it another one
(C<cluster_cidr>, or without it the default above), C<install_server> dies
with both values before anything is written or installed; that includes a
re-run that leaves C<cluster_cidr> out against a server set up with
another. Pass the value it runs with. A file there that cannot be read or
parsed dies too, with its name. A server not set up yet is not checked.

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
C<disable-kube-proxy: true> and C<cluster-cidr: 10.42.0.0/16> (or
C<cluster_cidr>) are written:
Flannel, k3s's embedded network policy controller and kube-proxy are
switched off, and Cilium takes over all three with kube-proxy replacement.
C<cluster-cidr> is k3s's own default, written out because Cilium's
cluster-pool IPAM is given the same range (see L<Rex::Rancher::Cilium>). These
are server settings that k3s agents take from the server; an additional
server joining with C<server> gets the same keys, as k3s requires them to
match across servers. The same keys and Cilium values were verified live in
kubernetes-ocp (k3s v1.36.4+k3s1, Cilium 1.20.0, Gateway API v1.6.1), the
Cilium version L<Rex::Rancher::Cilium> defaults to, and have since been run
live through Rex::Rancher's k3s path (a control plane with one worker; see
L<Rex::Rancher::Distribution::K3s>).

=item C<nvidia_runtime_path>

If true, and C<nvidia-container-runtime> is on the host's C<PATH>, write
C<PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin> to
C</etc/default/rke2-server> before the installer runs. The rke2 unit sets no
C<PATH>, and rke2 looks for the NVIDIA runtime only when the service starts;
without it a host- or vendor-installed toolkit (C</usr/bin>, e.g. DGX OS) is
not wired into containerd. Other lines of the file are kept, an existing
C<PATH=> line is replaced. If the file changed while the service is already
running, the service is restarted (see L</Re-runs>). The GPU
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

=head2 preflight_server(%opts)

  my $checked = Rex::Rancher::Server::preflight_server(%opts);
  # { version => ..., install_method => 'script', cluster_cidr => ... }

Everything L</install_server> checks before it writes or installs, with the
same options and in the same order, and nothing else: it only reads the
host. L</install_server> runs it first thing; L<Rex::Rancher/rancher_deploy_server>
runs it before it prepares the node, and a caller that prepares the node
on its own can do the same, so a refused host is left as it was. Not
exported.

=over

=item 1. the pure option checks: C<distribution>, C<install_method> (with
C<version>), C<cluster_cidr>;

=item 2. Cilium datapath state an earlier cluster left on a host without
RKE2 or K3s (L<Rex::Rancher::Uninstall/check_cilium_residue>), the first
read of the host;

=item 3. with C<hold_running>, the version to hold
(L<Rex::Rancher::Distribution/held_version>);

=item 4. the version skew against the running server or installed binary
(L<Rex::Rancher::Distribution/check_version_skew>), with the held version
under C<hold_running>, else C<version>;

=item 5. the C<cluster-cidr> of a server already set up on the host
(L<Rex::Rancher::Distribution/check_established_cluster_cidr>).

=back

Dies as L</install_server> would. Returns a hashref: the C<version> this run
installs (held, pinned, or C<undef> for the stable channel), the
C<install_method> and the C<cluster_cidr> (C<undef> when not given).

=head2 update_registries(%opts)

Update C<registries.yaml> on an already-running node and restart the
distribution service to pick up the new registry mirror configuration.

Use this to add or change registry mirrors after the cluster is up — for
example, after deploying an in-cluster registry that you want every node
to use as a pull-through cache.

Before the restart, an C<agent/etc/containerd/config.toml.tmpl> that holds
only C<imports> and C<version = 2>, as L<Rex::GPU> 0.001 wrote it, is
removed with a warning, for RKE2 and K3s alike: the restart would render it
instead of the distribution's own containerd config, which carries the
registry mirrors, so the new ones would not take effect. Any other template
stays, with a log line; no template changes nothing (see
L<Rex::Rancher::Distribution/remove_bare_containerd_template>). If the
removal fails, C<update_registries> dies after writing C<registries.yaml>
and before the restart, so nothing is restarted.

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

Note: RKE2 and K3s both write a loopback server address
(C<https://127.0.0.1>, see L</patch_kubeconfig_server>). The content comes
back as the node has it; L</fetch_kubeconfig> points it at an address that
works from elsewhere and saves it, as
L<Rex::Rancher/rancher_deploy_server> does.

Dies if the file cannot be read.

=head2 fetch_kubeconfig(%opts)

  my $kubeconfig = fetch_kubeconfig(
    distribution => 'rke2',
    server       => 'cp.example.com',
    file         => "$ENV{HOME}/.kube/cluster.yaml",
  );

The server's kubeconfig for use from this machine: read from the host Rex is
connected to (L</get_kubeconfig>, over the exec channel, no SFTP), pointed at
C<server> (L</patch_kubeconfig_server>), passed through C<filter> if given,
written to C<file> if given, and returned. The CA and the admin client
certificate and key are kept.

Options:

=over

=item C<distribution>

C<rke2> (default) or C<k3s>. Anything else dies before the host is read.

=item C<server>

The address the kubeconfig will reach the Kubernetes API at: a host name or
an IPv4/IPv6 address, without scheme or port. It must be a name the API
server certificate is made for (the node's own IPs and host name, or a
C<tls_san>), since the CA stays. Omitted, the kubeconfig keeps the loopback
address the node wrote, which works only on the node itself (a C<Local>
connection) or through a tunnel to its port 6443.

There is no fallback to the host Rex is connected to: the SSH address need
not be one the API is reached at or certified for (an F<ssh_config> alias, a
jump host, a NAT address). Where it is, pass it:
C<server =E<gt> connection-E<gt>server>.

=item C<filter>

A code reference. It gets the patched kubeconfig and returns the one to
write and return: the place for a caller's own policy, which this module
does not bring (see the example below). If it returns nothing (C<undef> or an
empty string), C<fetch_kubeconfig> dies and writes nothing. A C<filter> that
is not a code reference dies before the host is read.

=item C<file>

Local path the result is written to, mode C<0600> from the moment it exists:
the kubeconfig carries the cluster admin's client certificate and key. An
existing file is set to C<0600> before its content is replaced, in place, so
a symlink keeps pointing where it did. The directory must exist. Without
C<file> nothing is written.

=back

Dies naming the cause if the kubeconfig cannot be read from the host, is
empty, or cannot be written.

A caller that wants the CA dropped and certificate verification off, for
instance because it reaches the API at a name the certificate does not
carry, says so in C<filter>; this module keeps the CA itself:

  my $kubeconfig = fetch_kubeconfig(
    distribution => 'k3s',
    server       => connection->server,
    file         => "$ENV{HOME}/.kube/k3s.yaml",
    filter       => sub {
      my ( $kc ) = @_;
      $kc =~ s/^[ \t]*certificate-authority-data:.*\n//mg;
      $kc =~ s/^([ \t]*)(server: https:\/\/\S+)\n/$1$2\n$1insecure-skip-tls-verify: true\n/mg;
      return $kc;
    },
  );

=head2 patch_kubeconfig_server($content, $server)

  my $kubeconfig = patch_kubeconfig_server($content, '2001:db8::10');
  # server: https://[2001:db8::10]:6443

Return C<$content>, a kubeconfig as RKE2 or K3s wrote it, with its server
URL pointed at C<$server>. Pure: no host, no connection, so it serves a
kubeconfig read over any channel, not only through L</get_kubeconfig>.

RKE2 and K3s write C<https://127.0.0.1:PORT>, or C<https://[::1]:PORT> when
the cluster's (first) service CIDR is IPv6; both become
C<https://SERVER:PORT>, the port kept. Nothing else changes: the CA
(C<certificate-authority-data>) and the client certificate and key stay, so
C<$server> must be a name the API server certificate is made for. A server
URL that is not loopback (a configured C<bind-address>) is left alone.

C<$server> is a host name or an IPv4/IPv6 address, without scheme or port;
an IPv6 address is put in brackets (C<https://[2001:db8::10]:6443>), one
already in brackets is taken as it is. Dies without C<$content> or
C<$server>.

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
