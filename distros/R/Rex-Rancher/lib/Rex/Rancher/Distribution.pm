# ABSTRACT: What RKE2 and K3s differ in, and the host steps they share

package Rex::Rancher::Distribution;
our $VERSION = '0.003';
use v5.14.4;
use Moo;
use Module::Runtime qw( use_module );
use Rex::Commands::File ();
use Rex::Commands::Run ();
use Rex::Logger ();
use Rex::Rancher::Checksum;
use Rex::Rancher::Options;
use YAML::PP;
use YAML::PP::Common qw( PRESERVE_ORDER );
use namespace::autoclean;

# No `use utf8` here, on purpose: the die messages carry UTF-8 em dashes as
# byte strings, exactly as Rex::Rancher::Server always emitted them.


has role => (
  is      => 'ro',
  default => 'server',
  isa     => sub {
    die "role must be 'server' or 'agent'\n"
      unless defined $_[0] && ( $_[0] eq 'server' || $_[0] eq 'agent' );
  },
);


sub is_agent { $_[0]->role eq 'agent' }


sub distribution_classes {
  return {
    rke2 => 'Rex::Rancher::Distribution::RKE2',
    k3s  => 'Rex::Rancher::Distribution::K3s',
  };
}


# use_module, not a `use` at the top: the classes extend this one, which has
# to be complete (its attributes declared) before they load. Which one is
# needed is known only from the caller's distribution option, and only a
# name from distribution_classes is ever loaded.
sub new_for {
  my ( $class, $name, %args ) = @_;
  $name //= $class->default_distribution;
  my $impl = $class->distribution_classes->{$name}
    // die $class->unknown_distribution($name) . "\n";
  return use_module($impl)->new(%args);
}


sub default_distribution { 'rke2' }


sub unknown_distribution {
  my ( $class, $name ) = @_;
  my $default = $class->default_distribution;
  my @names   = ( $default, sort grep { $_ ne $default } keys %{ $class->distribution_classes } );
  my $last    = pop @names;
  return "Unknown distribution: $name (expected "
    . join( ', ', map { "'$_'" } @names ) . ( @names ? ' or ' : '' ) . "'$last')";
}



sub service {
  my ( $self ) = @_;
  return $self->is_agent ? $self->agent_service : $self->server_service;
}


sub config_file     { $_[0]->config_dir.'/config.yaml' }
sub registries_file { $_[0]->config_dir.'/registries.yaml' }


sub cni_bin_dir  { '/opt/cni/bin' }
sub cni_conf_dir { '/etc/cni/net.d' }


sub restart_services_cmd {
  my ( $self ) = @_;
  return 'systemctl restart '.$self->server_service.'.service 2>/dev/null || systemctl restart '
    .$self->agent_service.' 2>/dev/null';
}

#
# Option checks (pure -- they die before anything touches the host)
#


sub resolve_install_method { shift; Rex::Rancher::Options->resolve_install_method(@_) }
sub check_cluster_cidr     { shift; Rex::Rancher::Options->check_cluster_cidr(@_) }

#
# Release artifacts (install_method => 'artifact')
#


sub goarch {
  my ( $self, $uname ) = @_;
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


sub artifact_spec {
  my ( $self, $arch, $version ) = @_;

  die "install_method 'artifact' requires a version\n" unless $version;
  die "Invalid version '$version'\n" unless $version =~ /\A[A-Za-z0-9._+-]+\z/;

  (my $url_version = $version) =~ s/\+/%2B/g;
  my $base  = $self->release_url . '/' . $url_version;
  my $dir   = $self->artifact_dir;
  my $asset = $self->asset_name($arch);
  my $sums  = "sha256sum-$arch.txt";

  return {
    dir        => $dir,
    script     => "$dir/install.sh",
    script_url => $self->install_url,
    asset      => $asset,
    asset_url  => "$base/$asset",
    sums       => $sums,
    sums_url   => "$base/$sums",
  };
}


sub expected_sha256 { shift; Rex::Rancher::Checksum->expected_sha256(@_) }
sub sha256_of       { shift; Rex::Rancher::Checksum->sha256_of(@_) }
sub verify_sha256   { shift; Rex::Rancher::Checksum->verify_sha256(@_) }


sub download_cmd {
  my ( $self, $url, $dest, $progress ) = @_;
  # --progress-bar keeps output flowing during the ~60 MB tarball download,
  # so a long silent curl does not look like a hung channel.
  my $flags = $progress ? '-fL --progress-bar' : '-fsSL';
  return "curl $flags -o '$dest' '$url' 2>&1";
}


sub fetch_artifacts {
  my ( $self, $version ) = @_;
  my $distribution = $self->name;

  my $arch = $self->goarch(Rex::Commands::Run::run("uname -m", auto_die => 1));
  my $spec = $self->artifact_spec($arch, $version);
  my $dir  = $spec->{dir};

  Rex::Logger::info("Downloading $distribution $version artifacts for $arch to $dir");

  Rex::Commands::Run::run("rm -rf '$dir' && mkdir -p '$dir'", auto_die => 1);

  for my $dl (
    [ $spec->{script_url}, $spec->{script},             0 ],
    [ $spec->{sums_url},   "$dir/$spec->{sums}",        0 ],
    [ $spec->{asset_url},  "$dir/$spec->{asset}",       1 ],
  ) {
    my ($url, $dest, $progress) = @{$dl};
    my $out = Rex::Commands::Run::run($self->download_cmd($url, $dest, $progress), auto_die => 0);
    die "Download failed: $url\n"
      . ($progress ? "If this 404s, $distribution $version publishes no build for '$arch'.\n" : '')
      . ($out // '') . "\n"
      unless $? == 0;
  }

  my $sums   = Rex::Commands::Run::run("cat '$dir/$spec->{sums}'", auto_die => 1);
  my $actual = Rex::Commands::Run::run("sha256sum '$dir/$spec->{asset}'", auto_die => 1);
  # scalar(): both return empty on no match; in this list they must stay undef.
  $self->verify_sha256(scalar($self->expected_sha256($sums, $spec->{asset})),
    scalar($self->sha256_of($actual)), $spec->{asset});
  Rex::Logger::info("  $spec->{asset}: sha256 verified");

  return $spec;
}

#
# Server install step: artifact or script, then whatever the distribution
# needs to confirm it.
#


sub install_server_package {
  my ( $self, $server, $version, $method ) = @_;

  if (($method // 'script') eq 'artifact') {
    my $spec = $self->fetch_artifacts($version);
    Rex::Logger::info("Installing " . $self->label . " from verified artifact $spec->{asset}...");
    # auto_die => 1: with an artifact path RKE2's script takes its tarball
    # method, which has no GPG key import (the Rocky 10 noise that
    # Rex::Rancher::Distribution::RKE2 swallows is the RPM method's), so a
    # non-zero exit here is a real failure.
    Rex::Commands::Run::run($_, auto_die => 1)
      for $self->artifact_install_cmds($spec, $server, $version);
  }
  else {
    Rex::Logger::info("Installing " . $self->label . " via install script...");
    $self->run_server_install_script($server, $version);
  }
}

#
# Installed version
#


# "rke2 version v1.30.4+rke2r1 (abc)" / "k3s version v1.30.4+k3s1 (abc)";
# the first word is argv[0]'s basename, so through /proc/PID/exe it is
# "exe version v1.36.4+rke2r1 (7479a59c)" (k68). Not "go version go1.26.7".
sub parse_version_output {
  my ( $self, $out ) = @_;
  return $1 if ($out // '') =~ /^(?!go )\S+ version (\S+)/m;
  return;
}


sub same_version {
  my ( $self, $want, $got ) = @_;
  return 0 unless defined $want && defined $got;
  my ($w, $g) = ($want, $got);
  s/\Av// for $w, $g;
  return $w eq $g ? 1 : 0;
}


sub verify_installed_version {
  my ( $self, $version ) = @_;
  return 1 unless $version;

  my $distribution = $self->name;
  my $binary = $self->binary;
  my $out    = Rex::Commands::Run::run("$binary --version 2>&1", auto_die => 0);
  my $got    = $self->parse_version_output($out);
  die "Could not determine installed $distribution version ($binary --version):\n"
    . ($out // '') . "\n"
    unless defined $got;
  die "Installed $distribution version is $got, expected $version — the "
    . "install or upgrade did not take effect\n"
    unless $self->same_version($version, $got);
  Rex::Logger::info("  $distribution $got installed");
  return 1;
}

#
# Version skew: what may be installed over a running service, and when it
# may be restarted onto it. Kubernetes' version skew policy: a control plane
# moves one minor version at a time and never back, servers before agents,
# and a kubelet is never newer than the API server.
#


sub parse_release {
  my ( $self, $version ) = @_;
  return unless defined $version
    && $version =~ /\Av?(\d+)\.(\d+)\.(\d+)(?:-[0-9A-Za-z.-]+)?(?:\+(?:rke2r|k3s)(\d+))?\z/;
  return ( $1, $2, $3, $4 // 0 );
}


sub compare_versions {
  my ( $self, $x, $y ) = @_;
  my @a = $self->parse_release($x);
  my @b = $self->parse_release($y);
  return unless @a && @b;
  for my $i (0 .. 3) {
    my $cmp = $a[$i] <=> $b[$i];
    return $cmp if $cmp;
  }
  return 0;
}


sub version_skew {
  my ( $self, $from, $to ) = @_;
  my $cmp = $self->compare_versions($to, $from);
  return unless defined $cmp;
  return 'downgrade' if $cmp < 0;
  my @f = $self->parse_release($from);
  my @t = $self->parse_release($to);
  if ( $t[0] == $f[0] && $t[1] == $f[1] ) {
    return $self->same_version($from, $to) ? 'same' : 'patch';
  }
  return ( $t[0] == $f[0] && $t[1] == $f[1] + 1 ) ? 'minor' : 'jump';
}


sub parse_channel_redirect {
  my ( $self, $url ) = @_;
  return unless ($url // '') =~ m{/releases/tag/([^/\s]+)\s*\z};
  (my $version = $1) =~ s/%2B/+/gi;
  my @parts = $self->parse_release($version);
  return @parts ? $version : ();
}


sub channel_version {
  my ( $self ) = @_;
  my $out = Rex::Commands::Run::run("curl -fsSL -o /dev/null -w '%{url_effective}' '"
    . $self->channel_url . "' 2>/dev/null", auto_die => 0);
  return unless $? == 0;
  return $self->parse_channel_redirect($out);
}


sub main_pid {
  my ( $self ) = @_;
  return $self->parse_main_pid(Rex::Commands::Run::run(
    "systemctl show -p MainPID " . $self->service . " 2>/dev/null", auto_die => 0));
}


sub running_version {
  my ( $self, $pid ) = @_;
  return $self->parse_version_output(
    Rex::Commands::Run::run("/proc/$pid/exe --version 2>&1", auto_die => 0));
}

sub installed_version {
  my ( $self ) = @_;
  return $self->parse_version_output(
    Rex::Commands::Run::run($self->binary . " --version 2>&1", auto_die => 0));
}


sub held_version {
  my ( $self, %args ) = @_;
  my $pinned  = $args{version};
  my $service = $self->service;
  my $binary  = $self->binary;
  my $release = sub { defined $_[0] && $self->parse_release($_[0]) ? $_[0] : undef };

  my $pid = $self->main_pid;
  my ( $held, $from );
  if ($pid) {
    $held = $release->($self->running_version($pid));
    $from = "$service runs $held" if defined $held;
  }
  unless (defined $held) {
    $held = $release->($self->installed_version);
    $from = ( $pid ? '' : "$service is not running, " ) . "the installed $binary is $held"
      if defined $held;
    Rex::Logger::info("Could not ask the running $service (/proc/$pid/exe --version) for "
      . "its version: hold_running holds the installed $binary $held instead", 'warn')
      if $pid && defined $held;
  }

  unless (defined $held) {
    my $applies = defined $pinned && length $pinned
      ? "version $pinned applies"
      : "version is not pinned, the stable channel's applies";
    if ($pid) {
      Rex::Logger::info("Could not ask the running $service (/proc/$pid/exe --version) for "
        . "its version, and no installed $binary reports a version: hold_running holds "
        . "nothing, $applies", 'warn');
    }
    else {
      Rex::Logger::info("hold_running: $service is not running and no installed $binary "
        . "reports a version: $applies");
    }
    return $pinned;
  }

  if (defined $pinned && length $pinned && !$self->same_version($pinned, $held)) {
    Rex::Logger::info("hold_running: $from; that is the version for this run, not "
      . "version => '$pinned'", 'warn');
  }
  else {
    Rex::Logger::info("hold_running: $from; that is the version for this run");
  }
  return $held;
}


sub check_version_skew {
  my ( $self, %args ) = @_;
  my $pinned  = $args{version};
  my $server  = $args{server_version};
  my $service = $self->service;

  my $pid     = $self->main_pid;
  my $running = $pid ? $self->running_version($pid) : undef;
  Rex::Logger::info("Could not ask the running $service (/proc/$pid/exe --version) "
    . "for its version: the version skew is checked only after the install, "
    . "before $service is restarted", 'warn')
    if $pid && !defined $running;
  # Not running (stopped, crashed, never started): the binary on disk is what
  # the node last ran, and start_verb has nothing to hold back once the
  # installer replaced it. No binary: a fresh install, nothing to check.
  my $installed = $pid ? undef : $self->installed_version;
  return unless defined $running || defined $installed || defined $server;

  my $target = $pinned;
  unless (defined $target && length $target) {
    $target = $self->channel_version;
    unless (defined $target) {
      Rex::Logger::info("Could not resolve the version " . $self->channel_url
        . " would install: "
        . ( defined $installed
            ? "the version skew against the installed " . $self->binary . " $installed "
              . "is not checked, and $service, which is not running, starts on "
              . "whatever the install brings"
            : "the version skew is checked only after the install, before $service "
              . "is (re)started" ), 'warn');
      return;
    }
    Rex::Logger::info("version not pinned: the stable channel installs $target");
  }

  if (defined $running) {
    my $skew = $self->version_skew($running, $target) // '';
    die "Refusing to install " . $self->name . " $target"
      . ( $pinned ? '' : " (the stable channel's version; version is not pinned)" )
      . ": $service runs $running, and " . $self->_skew_rule($skew, $running)
      . " Nothing was installed; $service keeps running $running.\n"
      if $skew eq 'jump' || $skew eq 'downgrade';
  }
  elsif (defined $installed) {
    $self->_check_installed_skew($installed, $target, $pinned);
  }

  $self->check_agent_version($target, $server) if defined $server;
  return $target;
}

# The service is not running: against the binary it would have started on.
sub _check_installed_skew {
  my ( $self, $installed, $target, $pinned ) = @_;
  my $service = $self->service;
  my $binary  = $self->binary;
  my $skew    = $self->version_skew($installed, $target) // '';
  die "Refusing to install " . $self->name . " $target"
    . ( $pinned ? '' : " (the stable channel's version; version is not pinned)" )
    . ": $service is not running, and the installed $binary is $installed; "
    . $self->_skew_rule($skew, $installed)
    . " Nothing was installed; $binary $installed stays in place.\n"
    if $skew eq 'jump' || $skew eq 'downgrade';
  Rex::Logger::info("$service is not running, and the installed $binary is "
    . "$installed: the stable channel's $target, a new minor version, is "
    . "installed since version is not pinned, and $service starts on it. Pin "
    . "version => '$installed' to stay on it", 'warn')
    if $skew eq 'minor' && !$pinned;
  return;
}

sub _skew_rule {
  my ( $self, $skew, $running ) = @_;
  my @r = $self->parse_release($running);
  return $skew eq 'downgrade'
    ? "that is a downgrade, which Kubernetes' version skew policy does not "
      . "allow. Pin version to $running or newer."
    : "that skips a minor version: Kubernetes' version skew policy moves a "
      . "node one minor version at a time. Upgrade to a v$r[0]." . ($r[1] + 1)
      . " release first (pin version).";
}


sub check_agent_version {
  my ( $self, $agent, $server, $installed ) = @_;
  my @a = $self->parse_release($agent);
  my @s = $self->parse_release($server);
  unless (@a && @s) {
    Rex::Logger::info("Could not compare " . $self->name . " $agent with the control "
      . "plane's " . ( $server // 'unknown' ) . ": the agent is not checked against it",
      'warn');
    return;
  }
  return 1 if $a[0] < $s[0] || ( $a[0] == $s[0] && $a[1] <= $s[1] );
  die "Refusing the " . $self->name . " agent $agent: the control plane runs $server, "
    . "and a kubelet must never be of a newer minor version than the API server "
    . "(Kubernetes' version skew policy: servers first, then agents). "
    . ( $installed
        ? $self->binary . " $agent is installed, but " . $self->service . " was not (re)started."
        : "Nothing was installed." )
    . " Upgrade the servers first, or pin version to a v$s[0].$s[1] release.\n";
}

#
# Cluster CIDR: a server that is set up keeps the pod network it was set up
# with. Another cluster-cidr in config.yaml restarts it onto that range while
# its pods keep their addresses and the node podCIDRs and Cilium's pool stay
# on the old one (k67).
#


sub builtin_cluster_cidr { '10.42.0.0/16' }


sub is_established {
  my ( $self ) = @_;
  Rex::Commands::Run::run('systemctl is-active --quiet '.$self->server_service, auto_die => 0);
  return 1 if $? == 0;
  # Written once the control plane has bootstrapped its datastore.
  Rex::Commands::Run::run('test -e '.$self->_shell_quote($self->server_token), auto_die => 0);
  return $? == 0 ? 1 : 0;
}


sub established_cluster_cidr {
  my ( $self ) = @_;
  return unless $self->is_established;
  my ( @cidr, $from );
  for my $file ($self->_server_config_files) {
    my $config = $self->_read_server_config($file);
    # In the order of the file, as the distributions read it.
    for my $key (keys %{$config}) {
      next unless $key =~ /\Acluster-cidr(\+?)\z/;
      my $append = $1;
      my @value  = ref $config->{$key} eq 'ARRAY' ? @{ $config->{$key} } : ( $config->{$key} );
      die $self->_cluster_cidr_unknown(
        "$file: cluster-cidr is neither a string nor a list of strings")
        if grep { !defined || ref } @value;
      @cidr = ( ( $append ? @cidr : () ), @value );
      $from = $file;
    }
  }
  my $cidr = @cidr ? join(',', @cidr) : $self->builtin_cluster_cidr;
  $from = undef unless @cidr;
  return wantarray ? ( $cidr, $from ) : $cidr;
}


sub check_established_cluster_cidr {
  my ( $self, %args ) = @_;
  my ( $running, $from ) = $self->established_cluster_cidr;
  return unless defined $running;

  my $given = $args{cluster_cidr};
  my $want  = $given // ( $args{cilium} ? $self->cilium_config->{'cluster-cidr'} : undef )
    // $self->builtin_cluster_cidr;
  s/\A\s+//, s/\s+\z// for $running, $want;
  return $running if $running eq $want;

  my $name   = $self->name;
  my $config = $self->config_file;
  die "Refusing to install $name with cluster-cidr $want"
    . ( defined $given ? ' (cluster_cidr)' : ' (cluster_cidr not given: the default)' )
    . ": the $name server on this host was set up with $running ("
    . ( defined $from
        ? "from $from"
        : "${name}'s built-in default: no cluster-cidr in $config or $config.d" )
    . "), and the cluster-cidr of a running cluster cannot be changed. Pass "
    . "cluster_cidr => '$running'. config.yaml is unchanged and nothing was installed.\n";
}

# config.yaml if there, then the drop-ins k3s' configfilearg (RKE2 uses it
# too) takes: no directories, .yaml/.yml in any case, in os.ReadDir order.
sub _server_config_files {
  my ( $self ) = @_;
  my $config  = $self->config_file;
  my $dropins = $config.'.d';
  my @files;
  Rex::Commands::Run::run('test -e '.$self->_shell_quote($config), auto_die => 0);
  push @files, $config if $? == 0;
  Rex::Commands::Run::run('test -d '.$self->_shell_quote($dropins), auto_die => 0);
  return @files unless $? == 0;
  my $out = Rex::Commands::Run::run('find '.$self->_shell_quote($dropins)
    .' -mindepth 1 -maxdepth 1 ! -type d', auto_die => 0);
  die $self->_cluster_cidr_unknown("Could not list $dropins (find exited ".($? >> 8).")")
    unless $? == 0;
  push @files, sort grep { /\.ya?ml\z/i } split /\n/, $out // '';
  return @files;
}

sub _read_server_config {
  my ( $self, $file ) = @_;
  my $content = Rex::Commands::Run::run('cat '.$self->_shell_quote($file), auto_die => 0);
  die $self->_cluster_cidr_unknown("Could not read $file (cat exited ".($? >> 8).")")
    unless $? == 0;
  # Repeated keys are allowed, the last one wins, as in the distributions.
  # Never the parser's message: it quotes the line, which may be the token's.
  my @docs;
  unless (eval {
    @docs = YAML::PP->new(duplicate_keys => 1, preserve => PRESERVE_ORDER)
      ->load_string($content // '');
    1;
  }) {
    my ($line) = ($@ // '') =~ /^Line\s*:\s*(\d+)/m;
    die $self->_cluster_cidr_unknown("Could not parse $file as YAML"
      . ( defined $line ? " (line $line)" : '' ));
  }
  my $config = $docs[0] // {};
  die $self->_cluster_cidr_unknown("$file is not a YAML mapping") unless ref $config eq 'HASH';
  return $config;
}

sub _cluster_cidr_unknown {
  my ( $self, $what ) = @_;
  return "$what, so the cluster-cidr the ".$self->name." server on this host was set up "
    . "with is unknown. config.yaml is unchanged and nothing was installed.\n";
}

# One shell word, whatever the name: the drop-in names come from the host.
sub _shell_quote {
  my ( $self, $word ) = @_;
  $word =~ s/'/'\\''/g;
  return "'$word'";
}

#
# Service start and wait
#


sub start_verb {
  my ( $self, %args ) = @_;
  my $pid = $self->main_pid;
  return 'start' if $pid && $self->_hold_new_binary($pid, $args{pinned});
  return 'restart' if $self->_stale_containerd_restart;

  # k3s restarts anyway, unless held. A `start` of a running service is a
  # no-op, so it is turned into a restart exactly when the service runs on
  # something older than what is on disk now.
  my $default = $args{hold} ? 'start' : $self->default_start_verb;
  return $default unless $default eq 'start' && $pid;
  my @reasons = ( $self->_restart_reasons_for($pid), $self->_unit_rewritten($args{unit_digest}) );
  return $default unless @reasons;
  Rex::Logger::info("Restarting " . $self->service . ", which reads these only when "
    . "it starts: " . join('; ', @reasons));
  return 'restart';
}


sub installer_unit_digest {
  my ( $self ) = @_;
  my @files = $self->installer_unit_files or return;
  return Rex::Commands::Run::run('sha256sum ' . join(' ', map { $self->_shell_quote($_) } @files)
    . ' 2>&1', auto_die => 0) // '';
}

# The installer rewrote the unit or its env file with other content than
# before it ran: the service's arguments or environment (K3S_URL, proxies)
# changed, which it takes only when it starts.
sub _unit_rewritten {
  my ( $self, $before ) = @_;
  return unless defined $before;
  my $after = $self->installer_unit_digest // '';
  return if $after eq $before;
  return "rewritten by the installer with other content: "
    . join(', ', $self->installer_unit_files);
}

# A restart onto the installed binary, checked against the running one.
# Rejected upgrades die here too: check_version_skew could not see them
# before the install when the channel did not resolve or moved in between.
# An unpinned new minor stays installed but not running (maintainer
# decision, k56): an unpinned re-run must not silently upgrade a running
# control plane. KillMode=process keeps pods up across a restart either way.
sub _hold_new_binary {
  my ( $self, $pid, $pinned ) = @_;
  my $running   = $self->running_version($pid);
  my $installed = $self->installed_version;
  return 0 unless defined $running && defined $installed;
  my $skew    = $self->version_skew($running, $installed) // return 0;
  my $service = $self->service;
  my $binary  = $self->binary;

  die "$binary $installed is installed, but $service runs $running, and "
    . $self->_skew_rule($skew, $running) . " $service was not restarted and "
    . "keeps running $running; its next start (a reboot) runs $installed. "
    . "Install $running again (pin version) or a release the policy allows.\n"
    if $skew eq 'jump' || $skew eq 'downgrade';
  return 0 unless $skew eq 'minor' && !$pinned;

  Rex::Logger::info("$service was NOT restarted: it runs $running, and $installed "
    . "is now installed, a new minor version from the stable channel since "
    . "version is not pinned. It keeps running $running, and anything else "
    . "changed for it waits too, until its next start (a reboot starts "
    . "$installed). Pin version => '$installed' to have it restarted, or run: "
    . "systemctl restart $service", 'warn');
  return 1;
}

# Rex::GPU 0.001 wrote agent/etc/containerd/config.toml.tmpl as a bare
# `imports = [...]` + `version = 2`. rke2 renders a template instead of its
# own config, so config.toml became exactly that: no SystemdCgroup, sandbox
# image or registry mirrors. remove_bare_containerd_template (which
# install_server and install_agent run before this) and Rex::GPU 0.002's
# gpu_setup remove the template, but restart nothing, and config.toml is
# rewritten only when the service starts. So: config.toml still in that
# shape and the template gone, or replaced by another one since -> restart a
# running service once; the rendered config no longer matches, so the next
# re-run starts (a no-op) again. The bare template still there (start_verb
# asked without removing it first) -> a restart would render the same file:
# warn with what to do.
sub _stale_containerd_restart {
  my ( $self ) = @_;
  my $distribution = $self->name;
  my $service = $self->service;

  my $dir    = $self->containerd_dir;
  my $config = Rex::Commands::Run::run("cat $dir/config.toml 2>/dev/null", auto_die => 0);
  return 0 unless $self->is_bare_template_output($config);

  my $tmpl     = Rex::Commands::Run::run("cat $dir/config.toml.tmpl 2>/dev/null", auto_die => 0);
  my $has_tmpl = $? == 0;
  if ($has_tmpl && $self->is_bare_template_output($tmpl)) {
    Rex::Logger::info("$dir/config.toml.tmpl holds only imports and version = 2 (as "
      . "Rex::GPU 0.001 wrote it) and replaces ${distribution}'s own containerd config: "
      . "no SystemdCgroup, sandbox image or registry mirrors. Remove it "
      . "(remove_bare_containerd_template, as install_server and install_agent do) "
      . "and run: systemctl restart $service", 'warn');
    return 0;
  }

  Rex::Commands::Run::run("systemctl is-active --quiet $service", auto_die => 0);
  # Not running: the start renders a fresh config.toml anyway.
  return 0 unless $? == 0;
  Rex::Logger::info( $has_tmpl
    ? "$dir/config.toml was rendered from Rex::GPU 0.001's bare config.toml.tmpl, "
      . "which another template has replaced since; restarting $service so it "
      . "renders that one"
    : "$dir/config.toml was rendered from a config.toml.tmpl that is gone "
      . "(Rex::GPU 0.001's); restarting $service so it regenerates its "
      . "containerd config", 'warn');
  return 1;
}


# kubernetes-ocp before its k23 wrote the same two lines (its
# cleanup_legacy_containerd_template). Same narrow match as Rex::GPU 0.002's
# heal on gpu_setup; this covers a node re-run without Rex::GPU, or set up by
# kubernetes-ocp. `{{ template "base" . }}` or any further line keeps it.
sub remove_bare_containerd_template {
  my ( $self ) = @_;
  my $tmpl    = $self->containerd_dir.'/config.toml.tmpl';
  my $content = Rex::Commands::Run::run("cat $tmpl 2>/dev/null", auto_die => 0);
  # No template: nothing to do.
  return 0 unless $? == 0;

  unless ($self->is_bare_template_output($content)) {
    Rex::Logger::info("Keeping $tmpl: it is not Rex::GPU 0.001's bare template "
      . "(only imports and version = 2) but somebody's containerd configuration");
    return 0;
  }

  my $label   = $self->label;
  my $service = $self->service;
  Rex::Logger::info("Removing $tmpl: it holds only imports and version = 2 (Rex::GPU "
    . "0.001's bare template), which $label renders instead of its own containerd "
    . "config: no SystemdCgroup, sandbox image or registry mirrors", 'warn');
  # auto_die => 0 only to die naming the file: a template left in place would
  # be rendered again by the start that follows.
  my $out = Rex::Commands::Run::run("rm -f $tmpl 2>&1", auto_die => 0);
  die "Could not remove $tmpl, the bare containerd template that replaces "
    . "${label}'s own containerd config: " . ( ( $out // '' ) =~ s/\s+\z//r ) . "\n"
    . "$service was not (re)started.\n"
    unless $? == 0;
  return 1;
}


sub restart_watch {
  my ( $self ) = @_;
  my $containerd = $self->containerd_dir;
  return (
    $self->config_file,
    $self->config_dir.'/config.yaml.d',
    $self->registries_file,
    ( defined $self->env_file ? ( $self->env_file ) : () ),
    "$containerd/config.toml.tmpl",
    "$containerd/config-v3.toml.tmpl",
    "$containerd/config-v3.toml.d",
  );
}


sub restart_reasons {
  my ( $self ) = @_;
  my $pid = $self->main_pid;
  return unless $pid;
  return $self->_restart_reasons_for($pid);
}

sub _restart_reasons_for {
  my ( $self, $pid ) = @_;
  my $service = $self->service;

  my @reasons;

  # Epoch seconds, both on the host's clock. Only files written after that
  # second count, so one written in the second the process started is missed;
  # everything here is written before the start, minutes earlier.
  my $since = Rex::Commands::Run::run(
    "echo \$(( \$(date +%s) - \$(ps -o etimes= -p $pid) ))", auto_die => 0);
  if (($since // '') =~ /\A\s*(\d+)\s*\z/) {
    $since = $1;
    my $paths   = join(' ', map { "'$_'" } $self->restart_watch);
    my $changed = Rex::Commands::Run::run("find $paths -newermt \@$since 2>/dev/null", auto_die => 0);
    my @changed = grep { length } split /\n/, $changed // '';
    push @reasons, "changed since it started: " . join(', ', @changed) if @changed;
  }
  else {
    Rex::Logger::info("Could not tell when $service started (ps -o etimes= -p $pid): "
      . "changes to " . join(', ', $self->restart_watch) . " are not detected; "
      . "restart $service yourself if one of them changed", 'warn');
  }

  # /proc/PID/exe still runs a binary the installer replaced (unlinked).
  my $running   = $self->running_version($pid);
  my $installed = $self->installed_version;
  if (defined $running && defined $installed) {
    push @reasons, "it runs $running, $installed is installed"
      unless $self->same_version($running, $installed);
  }
  else {
    Rex::Logger::info("Could not compare the running $service (/proc/$pid/exe "
      . "--version) with the installed " . $self->binary . " --version: a new binary "
      . "is not detected; restart $service yourself after an upgrade", 'warn');
  }

  return @reasons;
}


sub parse_main_pid {
  my ( $self, $out ) = @_;
  return $1 if ($out // '') =~ /^MainPID=([1-9]\d*)\s*$/m;
  return;
}


# Same narrow match as Rex::GPU 0.002's _is_rke2_clobber_tmpl.
sub is_bare_template_output {
  my ( $self, $content ) = @_;
  return 0 unless defined $content && length $content;
  my @lines = grep { /\S/ && !/^\s*#/ } split /\n/, $content;
  return 0 unless @lines;
  my ($imports, $version2) = (0, 0);
  for my $l (@lines) {
    if    ($l =~ /^\s*imports\s*=/)         { $imports  = 1 }
    elsif ($l =~ /^\s*version\s*=\s*2\s*$/) { $version2 = 1 }
    else                                    { return 0 }
  }
  return ($imports && $version2) ? 1 : 0;
}


sub wait_for_service {
  my ( $self, %args ) = @_;
  my $service  = $self->service;
  my $attempts = $args{attempts} // 60;
  my $interval = $args{interval} // 10;
  my $hint     = $args{hint};

  Rex::Logger::info("Waiting for $service to become active...");

  my $state = '';
  for my $i (1 .. $attempts) {
    $state = Rex::Commands::Run::run("systemctl is-active $service", auto_die => 0);
    $state = '' unless defined $state;
    $state =~ s/\s+\z//;
    if ($state eq 'active') {
      Rex::Logger::info("  $service is active");
      return 1;
    }
    die $self->_service_failure("is failed", $hint) if $state eq 'failed';
    Rex::Logger::info("  $service is " . ($state || 'unknown') . " ($i/$attempts)");
    sleep $interval if $i < $attempts;
  }

  die $self->_service_failure(
    "did not become active within " . ($attempts * $interval) . "s (last state: "
      . ($state || 'unknown') . ")", $hint);
}

sub _service_failure {
  my ( $self, $reason, $hint ) = @_;
  my $service = $self->service;
  my $journal = Rex::Commands::Run::run("journalctl -u $service -n 50 --no-pager 2>&1", auto_die => 0);
  $journal = '' unless defined $journal;
  $journal =~ s/\s+\z//;
  return "$service $reason\n"
    . ( defined $hint ? "$hint\n" : '' )
    . "--- journalctl -u $service -n 50 ---\n"
    . ($journal eq '' ? '(no journal output)' : $journal) . "\n";
}

#
# NVIDIA runtime lookup: a PATH for the rke2 units.
#


sub runtime_path_line { 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' }


sub env_with_runtime_path {
  my ( $self, $current ) = @_;
  $current //= '';
  my @keep = grep { !/^\s*PATH=/ } split /\n/, $current;
  my $content = join('', map { $_."\n" } @keep, $self->runtime_path_line);
  return $content eq $current ? undef : $content;
}


# rke2-server/-agent.service carry no Environment= and read
# EnvironmentFile=-/etc/default/%N; rke2 scans PATH for nvidia-container-runtime
# at service start only, and the RKE2 GPU docs say to set PATH there. The rke2
# install script does not touch /etc/default, so this survives the install.
# k3s has no env_file: its agent code does the same scan and wired a host
# toolkit plus the nvidia RuntimeClass on a DGX without help (kubernetes-ocp,
# _configure_nvidia_runtime_path).
sub ensure_nvidia_runtime_path {
  my ( $self ) = @_;
  my $env_file = $self->env_file or return;

  unless (Rex::Commands::Run::can_run('nvidia-container-runtime')) {
    Rex::Logger::info("nvidia-container-runtime not on PATH, $env_file left alone "
      . "(the GPU Operator's toolkit is found without it)");
    return;
  }

  my $current = Rex::Commands::Run::run("cat $env_file 2>/dev/null", auto_die => 0);
  my $content = $self->env_with_runtime_path($? == 0 ? $current : '');
  unless (defined $content) {
    Rex::Logger::info("$env_file already carries the PATH for the NVIDIA runtime");
    return;
  }

  Rex::Logger::info("Writing PATH to $env_file for the NVIDIA runtime lookup");
  Rex::Commands::Run::run("mkdir -p /etc/default", auto_die => 1);
  # No secret in here: the file keeps its mode, a new one gets root's umask.
  Rex::Commands::File::file($env_file, content => $content);

  # Only on a re-run: the service reads the file when it starts.
  my $service = $self->service;
  Rex::Commands::Run::run("systemctl is-active --quiet $service", auto_die => 0);
  Rex::Logger::info("$service is running: it takes the new PATH at its next start "
    . "(install_server and install_agent restart it for that)")
    if $? == 0;
}


sub env_files {
  my ( $self ) = @_;
  my $class = ref $self || $self;
  return grep { defined } map { $class->new( role => $_ )->env_file } qw( server agent );
}

#
# Secret files: config.yaml, registries.yaml
#


# config.yaml carries the join token and registries.yaml may carry registry
# passwords, so both end up 0600 root:root. Rex's `file` writes content to a
# ".rex.tmp.<name>" sibling (LibSSH: `cat >` over an exec channel, no SFTP),
# renames it over the target and only then chmods -- the tmp file would be
# umask-mode (0644) in between. Pre-creating that tmp name at 0600 closes the
# window: `cat >` and SFTP open-truncate both keep an existing inode's mode,
# and the rename carries it to the target. The explicit chmod afterwards is
# what fixes an existing 0644 file whose content is unchanged (Rex then drops
# the tmp file and never touches the target), and fails loudly.
sub write_secret_file {
  my ( $self, $path, $content ) = @_;

  my $tmp = Rex::Commands::File::get_tmp_file_name($path);
  Rex::Commands::Run::run("install -m 600 -o root -g root /dev/null $tmp", auto_die => 1);

  Rex::Commands::File::file($path, content => $content);

  Rex::Commands::Run::run("chown root:root $path && chmod 600 $path", auto_die => 1);
}


sub write_registries {
  my ( $self, $registries ) = @_;

  my $registries_file = $self->registries_file;
  Rex::Logger::info("Writing registries config to $registries_file");

  $self->write_secret_file($registries_file,
    YAML::PP->new(boolean => 'JSON::PP')->dump_string($registries));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Distribution - What RKE2 and K3s differ in, and the host steps they share

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Rex::Rancher::Distribution;

  my $dist = Rex::Rancher::Distribution->new_for($opts{distribution});
  $dist->kubeconfig;          # /etc/rancher/rke2/rke2.yaml
  $dist->service;             # rke2-server

  my $agent = Rex::Rancher::Distribution->new_for('k3s', role => 'agent');
  $agent->service;            # k3s-agent.service
  $agent->wait_for_service(hint => 'It joins the cluster via ...');

=head1 DESCRIPTION

Everything L<Rex::Rancher::Server>, L<Rex::Rancher::Agent> and
L<Rex::Rancher::Cilium> need to know about RKE2 versus K3s lives in one
object: paths, service names, install script and release artifacts, and the
host steps both distributions share (artifact download and checksum, version
check, service start and wait, secret files, the NVIDIA runtime C<PATH>).
L<Rex::Rancher::Distribution::RKE2> and L<Rex::Rancher::Distribution::K3s>
implement the distribution-specific methods; a change to one wants the
other in the same edit. Use L</new_for> to get one: it loads the class.

What is the same for both and needs no host lives apart: the option checks
in L<Rex::Rancher::Options>, the checksum parsing in
L<Rex::Rancher::Checksum>.

This is an internal building block of the Rex tasks; the functions those
modules export are the interface for a Rexfile. The host steps use the Rex
DSL (C<run>, C<file>) of the current connection, like those functions.

=head2 role

C<server> (default) or C<agent>: which side of the distribution this object
speaks for. L</service> and L</env_file>, and the installer command lines
(L</script_install_cmd>, L</artifact_install_cmds>) follow it; everything
else is the same for both.

=head2 is_agent

True for C<< role => 'agent' >>.

=head2 distribution_classes

  Rex::Rancher::Distribution->distribution_classes
  # { rke2 => 'Rex::Rancher::Distribution::RKE2', k3s => '...::K3s' }

The distribution names C<distribution> options accept, each with the class
that implements it. A subclass may override it to add or replace one: its
own L</new_for> then loads and builds those classes, and
L</unknown_distribution> lists their names. The functions L<Rex::Rancher>
and its modules export ask this class, not a subclass.

=head2 new_for

  my $dist  = Rex::Rancher::Distribution->new_for('k3s');
  my $agent = Rex::Rancher::Distribution->new_for('rke2', role => 'agent');

The object for a C<distribution> option value; C<undef> means
L</default_distribution>. Anything not in L</distribution_classes> dies with
L</unknown_distribution> (C<Unknown distribution: NAME (expected 'rke2' or
'k3s')>). Further arguments go to C<new>. The class is loaded here, when it
is first asked for.

=head2 default_distribution

C<rke2>: what an absent C<distribution> option means.

=head2 unknown_distribution

  die Rex::Rancher::Distribution->unknown_distribution($name) . "\n";

The message for a C<distribution> option that is not in
L</distribution_classes>, without a newline: C<Unknown distribution: NAME
(expected 'rke2' or 'k3s')>, the L</default_distribution> named first.

=head2 name

C<rke2> or C<k3s>, as in the C<distribution> option.

=head2 label

C<RKE2> or C<K3s>, for log lines.

=head2 config_dir

C</etc/rancher/rke2> / C</etc/rancher/k3s>, without a trailing slash.

=head2 install_url

The official install script: C<https://get.rke2.io> / C<https://get.k3s.io>.

=head2 channel_url

The release channel the install script resolves an unpinned install
through: C<https://update.rke2.io/v1-release/channels/stable> /
C<https://update.k3s.io/v1-release/channels/stable>. It redirects to the
GitHub release tag of the version it would install.

=head2 kubeconfig

The kubeconfig the server writes (C<rke2.yaml> / C<k3s.yaml>).

=head2 token_file

The node join token the server writes (C<server/node-token>).

=head2 server_token

The token the control plane is sealed with (C<server/token>).

=head2 default_disable

A new arrayref of the packaged components switched off when C<disable> is
not given.

=head2 default_cluster_cidr

The pod network written out (and handed to Cilium's cluster-pool) when
C<cilium> is on and C<cluster_cidr> is not given: C<10.42.0.0/16> on K3s,
C<undef> on RKE2, which keeps its own default unwritten.

=head2 binary

The distribution binary (C<rke2> / C<k3s>), asked for C<--version>.

=head2 uninstall_scripts

The uninstall scripts the distribution's installer puts on C<PATH>, for
either L</role>: C<rke2-uninstall.sh> (RKE2, server and agent) /
C<k3s-uninstall.sh> and C<k3s-agent-uninstall.sh> (K3s names it after the
service it set up). L<Rex::Rancher::Uninstall/uninstall_node> runs every one
that is there.

=head2 release_url

The GitHub release download base the artifacts come from.

=head2 artifact_dir

Where C<install_method =E<gt> 'artifact'> downloads to on the host.

=head2 containerd_dir

The directory holding the generated containerd C<config.toml>.

=head2 server_service

The server's systemd unit: C<rke2-server> / C<k3s>.

=head2 agent_service

The agent's systemd unit: C<rke2-agent.service> / C<k3s-agent.service>.
Unlike L</server_service> with the C<.service> suffix: both are handed to
C<systemctl> and C<journalctl> and named in log lines and errors exactly
like this, so the asymmetry is kept.

=head2 env_file

The C<EnvironmentFile> of the L</role>'s unit that gets the C<PATH> for the
NVIDIA runtime lookup, or C<undef> where none is needed (K3s).

=head2 default_start_verb

How the service is started when its containerd config is not stale:
C<start> (RKE2: a running service is restarted only for
L</restart_reasons>) or C<restart> (K3s, on every run, as its install
script did, unless C<hold_running>: see L</start_verb>). Either way
L</start_verb> checks the version skew first, and an unpinned new minor
version leaves a running service of either distribution alone.

=head2 installer_unit_files

The files the distribution's install script rewrites on every run and the
L</service> reads only when it starts, for L</installer_unit_digest>: on
K3s the unit and its env file, C</etc/systemd/system/k3s.service> and
C<k3s.service.env> (agent: C<k3s-agent.service>, C<.env>); none on RKE2,
whose unit comes with the version installed.

=head2 asset_name

  $dist->asset_name('arm64')   # rke2.linux-arm64.tar.gz / k3s-arm64

The release artifact for a GOARCH.

=head2 cilium_config

The C<config.yaml> keys that leave pod networking, network policy and
kube-proxy to Cilium, as a new hashref with real booleans.

=head2 default_ipam_mode

Cilium's IPAM mode on a fresh install when C<ipam_mode> is not given:
C<kubernetes> on RKE2 (pods take the node C<podCIDR>s cut from the
cluster's C<cluster-cidr>), C<cluster-pool> on K3s (Cilium's own pool).

=head2 cilium_helm_defaults

  $dist->cilium_helm_defaults(cluster_cidr => $cidr, k8s_service_host => $host,
                              ipam_mode => $mode)

The distribution's part of Cilium's default Helm values, as a new hashref
with real booleans, for L<Rex::Rancher::Cilium> to merge over the values
both share: C<cni.exclusive>, C<k8sServiceHost> and the IPAM mode and
pool. The mode is C<ipam_mode>, or L</default_ipam_mode> without one. RKE2:
not exclusive (its CNI config stays), C<127.0.0.1>, C<cluster_cidr> as the
pool (used only in C<cluster-pool> mode). K3s: exclusive,
C<k8s_service_host>, the pool on C<cluster_cidr> or
L</default_cluster_cidr>.

=head2 needs_k8s_service_host

True where Cilium's kube-proxy replacement needs the control plane's
address from the caller (K3s: its agents serve the API on
C<127.0.0.1:6444>, not C<6443>); false where every node serves it on
C<127.0.0.1:6443> (RKE2), which then refuses a C<k8s_service_host>.

=head2 gateway_api_crd_chart

The packaged Helm chart that brings its own Gateway API CRDs and has to be
disabled for C<gateway_api>: C<rke2-gateway-api-crd> on RKE2 (v1.37+),
C<undef> on K3s.

=head2 live_verified

True for a distribution that has been deployed live through Rex::Rancher:
RKE2 and K3s both. For one that has not,
L<Rex::Rancher::Server/install_server> warns.

=head2 script_install_cmd

  $dist->script_install_cmd($server, $version)

The C<curl | sh> install line for the L</role>. C<$server> (join URL) and
C<$version> may be C<undef>. The token is never on it.

=head2 artifact_install_cmds

  $dist->artifact_install_cmds($spec, $server, $version)

The command lines that install from a verified L</fetch_artifacts> spec, in
order, for the L</role>. Each has to succeed.

=head2 run_server_install_script

  $dist->run_server_install_script($server, $version)

Run L</script_install_cmd> for a server, with the exit-status handling the
distribution's install script needs.

=head2 service

The unit of the L</role>: L</server_service> or L</agent_service>.

=head2 config_file

C<config.yaml> in L</config_dir>.

=head2 registries_file

C<registries.yaml> in L</config_dir>.

=head2 cni_bin_dir

Where the kubelet of either distribution looks for CNI binaries once its
own CNI is off, C</opt/cni/bin>: Cilium's C<cni.binPath>.

=head2 cni_conf_dir

Where it looks for CNI configuration, C</etc/cni/net.d>: Cilium's
C<cni.confPath>.

=head2 restart_services_cmd

The line L<Rex::Rancher::Server/update_registries> runs: restart the server
unit, or the agent unit if that fails.

=head2 resolve_install_method

The same as L<Rex::Rancher::Options/resolve_install_method>, which is not
distribution-specific; kept here for callers of this class.

=head2 check_cluster_cidr

The same as L<Rex::Rancher::Options/check_cluster_cidr>; kept here for
callers of this class.

=head2 goarch

  Rex::Rancher::Distribution->goarch("aarch64\n")   # arm64

The GOARCH release artifacts are named by, from C<uname -m> output. Dies
for anything but amd64 and arm64.

=head2 artifact_spec

  my $spec = $dist->artifact_spec($arch, $version);

Where the install script, the artifact and its checksum file come from and
go to: a hashref with C<dir>, C<script>, C<script_url>, C<asset>,
C<asset_url>, C<sums> and C<sums_url>. Dies without a version or for one
with characters a URL or shell line must not carry.

=head2 expected_sha256

The same as L<Rex::Rancher::Checksum/expected_sha256>, which is not
distribution-specific; kept here for callers of this class, and as what
L</fetch_artifacts> calls, so a subclass can override it.

=head2 sha256_of

The same as L<Rex::Rancher::Checksum/sha256_of>, kept as
L</expected_sha256> is.

=head2 verify_sha256

The same as L<Rex::Rancher::Checksum/verify_sha256>, kept as
L</expected_sha256> is.

=head2 download_cmd

  $dist->download_cmd($url, $dest, $progress)

The C<curl> line that downloads C<$url> to C<$dest> on the host; with
C<$progress> it shows a progress bar.

=head2 fetch_artifacts

  my $spec = $dist->fetch_artifacts($version);

Download install script, artifact and checksum file on the host (C<curl>,
no SFTP, no upload) into an emptied L</artifact_dir>, for the host's own
architecture, and verify the artifact. Dies on any failure. Returns the
L</artifact_spec>.

=head2 install_server_package

  $dist->install_server_package($server, $version, $method);

Put the distribution onto a server host with C<$method> (C<script> or
C<artifact>). Installing only: the version check and the service start
are the caller's.

=head2 parse_version_output

The version in C<--version> output of rke2 or k3s, or nothing. Its first
word is the name the binary was called by: C<rke2 version ...> /
C<k3s version ...> for L</binary>, C<exe version ...> through
C</proc/PID/exe> (L</running_version>). The C<go version ...> line never
counts.

=head2 same_version

C<1> when both versions are given and equal, ignoring a leading C<v>.

=head2 verify_installed_version

  $dist->verify_installed_version($version);

Without C<$version> returns C<1> at once. Otherwise asks L</binary> for its
version and dies unless it is C<$version>: a failed pinned install or
upgrade leaves the old binary in place.

=head2 parse_release

  my @v = $dist->parse_release('v1.30.4+rke2r1');   # (1, 30, 4, 1)

Pure: major, minor, patch and the distribution revision (C<rke2rN> /
C<k3sN>; C<0> without one) of a version, or nothing for anything not shaped
C<vMAJOR.MINOR.PATCH>.

=head2 compare_versions

  $dist->compare_versions($x, $y)   # -1, 0 or 1

Pure: C<< <=> >> over L</parse_release>, C<undef> when either does not
parse.

=head2 version_skew

  $dist->version_skew($running, $new)

Pure: what moving from C<$running> to C<$new> is. C<same>; C<patch> (same
minor, newer, or only a pre-release tag differs); C<minor> (exactly the next
minor); C<jump> (more than one minor, or another major); C<downgrade>
(older, patch or revision included). C<undef> when either does not parse.

=head2 parse_channel_redirect

Pure: the version at the end of the release tag URL L</channel_url>
redirects to (C<.../releases/tag/v1.36.4+rke2r1>, C<%2B> decoded), or
nothing.

=head2 channel_version

The version an unpinned install would get: L</channel_url> resolved on the
host with C<curl>, as the install script resolves it there. Nothing when
that fails.

=head2 main_pid

The main PID of the L</service>, or nothing when it is not running. Reads
the host (C<systemctl show -p MainPID>).

=head2 running_version

  $dist->running_version($pid)

The version the process C<$pid> runs (C</proc/PID/exe --version>: the
binary it was started from, even when the installer has replaced it on
disk since; called that way it answers C<exe version ...>), or nothing.

=head2 installed_version

The version the installed L</binary> reports, or nothing.

=head2 held_version

  my $version = $dist->held_version(version => $pinned);

What C<hold_running> holds a run to, read from the host and meant to be
used as C<version> from there on: for L</check_version_skew>, the installer,
L</verify_installed_version> and L</start_verb> (C<pinned>). Writes
nothing, so it can be asked before anything else is.

The L</running_version> of the L</service> when it runs (L</main_pid>);
when it does not run, the L</installed_version>, the binary it would start
on; with neither, C<version> as given, or C<undef> without one (unpinned,
the stable channel, as without C<hold_running>). A running service whose
version cannot be read falls back to the installed binary, and without one
to C<version>, each with a warning. A version that is not shaped like a
release (L</parse_release>) counts as unreadable: it goes onto an installer
line.

A held version other than C<version> wins; a warning names both. Every
other outcome is logged as info.

=head2 check_version_skew

  $dist->check_version_skew(version => $pinned, server_version => $cp);

Before anything is installed: die when what would be installed breaks the
version skew policy, with nothing on the host changed.

The version to install is C<version>, or without one L</channel_version>.
Against a running L</service> (its L</running_version>), a L</version_skew>
of C<jump> or C<downgrade> dies. With C<server_version> (the control plane's
version, for an agent), a version of a newer minor than it dies too.

When the L</service> is not running (stopped, crashed, never started), the
reference is the L</installed_version> instead, the binary it would start
on: C<jump> or C<downgrade> dies the same way, and C<minor> without
C<version> warns that the service starts on the new minor (nothing holds a
stopped service back once the installer replaced its binary). No binary
there: a fresh install, nothing to check.

Nothing to compare against and no C<server_version>: nothing asked beyond
L</main_pid> and L</installed_version>. A channel that cannot be resolved,
or a running version that cannot be read, is a warning, not a die: for a
running service L</start_verb> checks the installed binary against the
running one again before it restarts anything; a stopped one is not
checked again.

=head2 check_agent_version

  $dist->check_agent_version($agent_version, $control_plane_version);
  $dist->check_agent_version($agent_version, $control_plane_version, 1);

Die when the agent version is of a newer minor (or major) than the control
plane's: a kubelet must never be newer than the API server. A newer patch of
the same minor is fine. The message says nothing was installed, or with a
true third argument that the binary is installed but the L</service> was not
(re)started. Two versions that do not parse only warn.

=head2 builtin_cluster_cidr

C<10.42.0.0/16>: the C<cluster-cidr> RKE2 and K3s run with when none is
configured. Unlike L</default_cluster_cidr> it says nothing about what is
written.

=head2 is_established

True when a server of the distribution is set up on the host: its
L</server_service> is active, or L</server_token> is there (a server that
bootstrapped and is stopped starts on its configuration again). Reads the
host.

=head2 established_cluster_cidr

  my ( $cidr, $from ) = $dist->established_cluster_cidr;

The C<cluster-cidr> of the server set up on the host (L</is_established>)
and the file it comes from (in scalar context the C<cluster-cidr> alone);
nothing when none is set up. Read over the exec channel (C<cat>, no SFTP)
from L</config_file> and its C<config.yaml.d> drop-ins, merged as RKE2 and
K3s merge them: C<config.yaml> first, then the drop-ins named C<*.yaml> or
C<*.yml> (any case) sorted by name; the last value wins, and
C<cluster-cidr+> appends to an earlier one. A list comes back
comma-separated. Set in none of them: L</builtin_cluster_cidr>, and no
file.

A file that is not there is skipped. One that cannot be read or parsed, is
not a YAML mapping, or holds anything but a string or a list of strings as
C<cluster-cidr> dies with its name (never its content: C<config.yaml> holds
the join token), since the value is then unknown.

=head2 check_established_cluster_cidr

  $dist->check_established_cluster_cidr(cluster_cidr => $cidr, cilium => $cilium);

Before anything is written: die when a server is set up on the host and
the L</established_cluster_cidr> is not the C<cluster-cidr> this run gives
it -- C<cluster_cidr>, else what L</cilium_config> writes when C<cilium> is
true, else L</builtin_cluster_cidr> -- compared as strings, trimmed. The
message names both and says to pass the established one. Returns that,
or nothing when no server is set up.

=head2 start_verb

  $dist->start_verb(pinned => defined $version);
  $dist->start_verb(pinned => 1, hold => 1, unit_digest => $before);

C<start> or C<restart> for the L</service>. Reads the host.

First the installed L</binary> against the running one (L</version_skew>),
for both distributions: C<jump> or C<downgrade> dies, and the service is
not touched. C<minor> without C<pinned> is C<start>, which leaves a running
service on its old binary, with a warning that says so and how to restart
it; nothing else below is asked. C<patch>, or C<minor> with C<pinned>,
restarts as any other change does.

Then C<restart> when a running service's containerd C<config.toml> is still
the output of L<Rex::GPU> 0.001's bare C<config.toml.tmpl> and the template
is gone (L</remove_bare_containerd_template>, which
L<Rex::Rancher::Server/install_server> and
L<Rex::Rancher::Agent/install_agent> run first) or replaced by another one,
with a warning, so it renders that config anew; the bare template still in
place only warns with what to do. Otherwise L</default_start_verb>,
and where that is C<start> (RKE2), C<restart> when L</restart_reasons> has
any, logging them: a running service reads its configuration only when it
starts.

With C<hold> (C<hold_running>, whose held version is C<pinned>) it is
C<start> for K3s too, turned into C<restart> the same way, and also when
C<unit_digest> is given (L</installer_unit_digest> taken before the
installer ran) and the L</installer_unit_files> now have other content --
the check K3s' own install script makes before it restarts K3s. For RKE2
C<hold> changes nothing.

=head2 installer_unit_digest

  my $before = $dist->installer_unit_digest;

C<sha256sum> of the L</installer_unit_files> on the host, errors included
(a file that is not there yet), as K3s' install script takes it to decide
whether it restarts K3s; C<undef> without such files (RKE2), with nothing
asked. Compared with a second one after the installer ran by
L</start_verb>'s C<unit_digest>.

=head2 remove_bare_containerd_template

  $dist->remove_bare_containerd_template;

Before the L</service> is (re)started: remove C<config.toml.tmpl> in
L</containerd_dir> when it is L<Rex::GPU> 0.001's bare template
(L</is_bare_template_output>: only C<imports> and C<version = 2>), which the
distribution would render instead of its own containerd config. Decided by
content, never by path: any other template is somebody's configuration and
stays, with a log line. No template: nothing. Reads with C<cat> and removes
with C<rm -f> (no SFTP); dies when the removal fails. Restarts nothing
itself: L</start_verb> then restarts a running service whose C<config.toml>
is still that template's output. C<1> when it removed the template, else
C<0>.

=head2 restart_watch

The paths the L</role>'s service reads only when it starts and that
Rex::Rancher or L<Rex::GPU> write:
L</config_file>, C<config.yaml.d>, L</registries_file>, L</env_file> (if
any), and in L</containerd_dir> C<config.toml.tmpl>, C<config-v3.toml.tmpl>
and the C<config-v3.toml.d> drop-ins (where L<Rex::GPU> puts
C<99-nvidia.toml>). Paths that do not exist are fine.

Not the distribution's own output (the kubeconfig, C<config.toml>), which
it rewrites on every start.

=head2 restart_reasons

  my @why = $dist->restart_reasons;

Why the running L</service> would have to be restarted to run what is on
the host now, as log-ready strings; empty when it is not running or nothing
changed. Reads the host:

=over

=item * a L</restart_watch> path modified (mtime) after the service's main
process started. Rex's C<file> leaves a file with unchanged content
untouched, so a re-run with the same options changes nothing; a change left
behind by an interrupted earlier run, or made by hand, counts too. This
covers the NVIDIA runtime's registration: the L</env_file> C<PATH> line and
L<Rex::GPU>'s C<config-v3.toml.d> drop-in. An upgraded
C<nvidia-container-runtime> binary alone is no reason: containerd runs it
anew for every container it creates.

=item * the running binary (C</proc/PID/exe --version>) reports another
version than the installed L</binary>. Whether it may be restarted onto
that version is L</start_verb>'s decision, which asks first.

=back

What it cannot determine (no C<ps>, a binary that does not answer
C<--version>) counts as unchanged, with a warning that names it.

=head2 parse_main_pid

The PID in C<systemctl show -p MainPID> output (C<MainPID=1234>), or
nothing for C<0> (not running) and anything else.

=head2 is_bare_template_output

  $dist->is_bare_template_output($config_toml)

Pure: is this C<config.toml> the verbatim output of L<Rex::GPU> 0.001's
template -- ignoring blank lines and comments, exactly an C<< imports = >> and a
C<version = 2> line and nothing else? The distributions' own configs always
have C<[plugins...]> sections.

=head2 wait_for_service

  $dist->wait_for_service;
  $dist->wait_for_service(hint => 'It joins the cluster via ...');

Poll C<systemctl is-active> for the L</service> until it is C<active>
(C<attempts>, default 60, every C<interval> seconds, default 10). C<failed>
dies at once, any other state is polled until the timeout, which dies too.
Either die message carries the reason, then C<hint> if given, then the last
50 lines of the unit's journal.

=head2 runtime_path_line

The C<PATH=> line L</ensure_nvidia_runtime_path> writes: systemd's own
default directories, not the SSH session's C<PATH>, since it becomes the
environment of a service running as root.

=head2 env_with_runtime_path

  $dist->env_with_runtime_path($current)

Pure: the env file with exactly one C<PATH> line (L</runtime_path_line>,
last), every other line kept in order. C<undef> when the file already is
exactly that.

=head2 ensure_nvidia_runtime_path

When the L</role>'s unit has an L</env_file> and C<nvidia-container-runtime>
is on the host's C<PATH>, make that file carry L</runtime_path_line>, other
lines kept. Restarts nothing itself: the file is in L</restart_watch>, so
the L</start_verb> of an RKE2 service running since before the write is
C<restart>.

=head2 env_files

  my @files = $dist->env_files;

The L</env_file> of either L</role>, server first, leaving out a role
without one: C</etc/default/rke2-server> and C</etc/default/rke2-agent> on
RKE2, none on K3s. Pure; also a class method. For
L<Rex::Rancher::Uninstall/uninstall_cmd>, which does not know the role a
host had.

=head2 write_secret_file

  $dist->write_secret_file($path, $content);

Write C<$content> to C<$path> on the host as C<0600 root:root>, with no
moment in which it is readable by others. Dies if the mode cannot be set.

=head2 write_registries

  $dist->write_registries($registries);

Write the registry mirror hashref to L</registries_file> through
L</write_secret_file>.

=head1 SEE ALSO

L<Rex::Rancher>, L<Rex::Rancher::Server>, L<Rex::Rancher::Agent>,
L<Rex::Rancher::Cilium>, L<Rex::Rancher::Distribution::RKE2>,
L<Rex::Rancher::Distribution::K3s>, L<Rex::Rancher::Options>,
L<Rex::Rancher::Checksum>

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
