# ABSTRACT: Linux node preparation for Rancher Kubernetes distributions (RKE2/K3s)

package Rex::Rancher::Node;
our $VERSION = '0.003';
use v5.14.4;
use warnings;

use Rex::Commands::File;
use Rex::Commands::Gather;
use Rex::Commands::Host;
use Rex::Commands::Pkg;
use Rex::Commands::Run;
use Rex::Logger;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  prepare_node
);


sub prepare_node {
  my (%opts) = @_;

  my $hostname = $opts{hostname};
  my $domain   = $opts{domain};
  my $timezone = $opts{timezone} // 'UTC';
  my $locale   = $opts{locale}   // 'en_US.UTF-8';
  my $ntp      = exists $opts{ntp} ? $opts{ntp} : 1;

  my $fqdn = ($hostname && $domain) ? "$hostname.$domain" : undef;

  # Before anything runs: the locale and the timezone end up in shell
  # commands (and the timezone in a path under /usr/share/zoneinfo).
  die "locale must look like en_US.UTF-8 (language_TERRITORY.charset\@modifier: "
    . "letters, digits, _ and -), got '$locale'\n"
    unless $locale =~ /\A[A-Za-z0-9_]+(?:\.[A-Za-z0-9-]+)?(?:\@[A-Za-z0-9]+)?\z/;
  die "timezone must look like Europe/Berlin, UTC or Etc/GMT+5 (a zoneinfo "
    . "name: parts of letters, digits, _, + and -, each starting with a "
    . "letter, separated by /), got '$timezone'\n"
    unless $timezone =~ m{\A[A-Za-z][A-Za-z0-9_+-]*(?:/[A-Za-z][A-Za-z0-9_+-]*)*\z};

  Rex::Logger::info("Preparing node " . ($fqdn // "(unnamed)") . " for Kubernetes");

  _install_base_packages();
  if ($hostname) {
    _set_hostname($hostname, $fqdn);
    _set_hosts_entry($hostname, $fqdn);
  }
  _set_timezone($timezone);
  _set_locale($locale);
  _setup_ntp() if $ntp;
  _disable_swap();
  _load_kernel_modules();
  _configure_sysctl();

  Rex::Logger::info("Node preparation complete" . ($fqdn ? " for $fqdn" : ""));
}

sub _install_base_packages {
  Rex::Logger::info("Installing base packages");
  if (is_debian()) {
    # Stop automatic apt services first — on a fresh Hetzner boot,
    # unattended-upgrades holds /var/lib/dpkg/lock-frontend and apt-get
    # fails immediately (DPkg::Lock::Timeout only covers the dpkg lock,
    # not the apt frontend lock).
    run "systemctl stop unattended-upgrades apt-daily.service apt-daily-upgrade.service 2>/dev/null || true",
      auto_die => 0;
    run "apt-get -o DPkg::Lock::Timeout=120 update -q", auto_die => 0;
  }
  pkg ["curl", "ca-certificates"], ensure => "present";
}

# A re-run must not rename a running node: without node-name in config.yaml
# rke2/k3s register the kernel hostname, and setting the short name over the
# FQDN a provider or installer wrote changes it at the next start (k86).
# Hostnames are case-insensitive, and the kubelet lowercases the node name.
sub _set_hostname {
  my ($hostname, $fqdn) = @_;
  my $static = _static_hostname();
  if (defined $static && lc((split /\./, $static, 2)[0]) eq lc $hostname) {
    Rex::Logger::info("Static hostname is already $static, leaving it"
      . (lc $static eq lc $hostname ? "" : " (first label matches $hostname)"));
    return;
  }
  Rex::Logger::info("Setting hostname to $hostname");
  if (can_run("hostnamectl")) {
    run "hostnamectl set-hostname $hostname", auto_die => 0;
  }
  else {
    file "/etc/hostname", content => "$hostname\n";
    run "hostname $hostname", auto_die => 0;
  }
}

# The static hostname from /etc/hostname: the file hostnamectl persists it in
# and the fallback above writes, readable over an exec channel without SFTP,
# D-Bus or a systemd-version-specific hostnamectl flag. The first line that
# is neither blank nor a # comment, as systemd reads it; undef when the file
# is missing, unreadable or holds no name.
sub _static_hostname {
  my $out = run "cat /etc/hostname 2>/dev/null", auto_die => 0;
  return if $? != 0 || !defined $out;
  for my $line (split /\n/, $out) {
    $line =~ s/\A\s+|\s+\z//g;
    return $line if length $line && $line !~ /\A#/;
  }
  return;
}

sub _set_hosts_entry {
  my ($hostname, $fqdn) = @_;
  if ($fqdn) {
    Rex::Logger::info("Configuring /etc/hosts for $fqdn");
    host_entry $fqdn,
      ensure  => "present",
      ip      => "127.0.1.1",
      aliases => [$hostname];
    return;
  }
  # Without a domain only add a missing name: host_entry replaces every line
  # naming the host -- the provider's public-IP line, or a
  # "127.0.0.1 localhost <hostname>" line and localhost with it.
  if (get_host($hostname)) {
    Rex::Logger::info("/etc/hosts already names $hostname, leaving it");
    return;
  }
  Rex::Logger::info("Configuring /etc/hosts for $hostname");
  host_entry $hostname,
    ensure => "present",
    ip     => "127.0.1.1";
}

# The timezone is validated in prepare_node: no quote can end the single
# quotes, and no part can be . or .. to leave /usr/share/zoneinfo.
sub _set_timezone {
  my ($timezone) = @_;
  Rex::Logger::info("Setting timezone to $timezone");
  if (can_run("timedatectl")) {
    run "timedatectl set-timezone '".$timezone."'", auto_die => 0;
  }
  else {
    run "ln -sf '/usr/share/zoneinfo/".$timezone."' /etc/localtime", auto_die => 0;
    file "/etc/timezone", content => "$timezone\n";
  }
}

sub _set_locale {
  my ($locale) = @_;
  Rex::Logger::info("Setting locale to $locale");
  # Generate first: localectl refuses a locale that is not installed.
  _generate_locale($locale) if is_debian();
  if (can_run("localectl")) {
    run "localectl set-locale LANG=$locale", auto_die => 0;
  }
  else {
    file "/etc/default/locale", content => "LANG=$locale\n";
  }
}

# Debian/Ubuntu only. Debian's locale-gen ignores its arguments and builds
# what /etc/locale.gen enables, Ubuntu's generates the locale it is given;
# enabling the line and naming the locale covers both.
sub _generate_locale {
  my ($locale) = @_;
  return if $locale =~ /^(?:C|POSIX)(?:\.|$)/;
  unless (can_run("locale-gen")) {
    Rex::Logger::info("locale-gen not installed, $locale is not generated", 'warn');
    return;
  }
  my ($name, $charset) = _locale_gen_name($locale);
  run _enable_locale_cmd($name.' '.$charset, '/etc/locale.gen'), auto_die => 0
    if $charset;
  run "locale-gen $name", auto_die => 0;
  Rex::Logger::info("locale-gen $name failed", 'warn') if $? != 0;
}

# The locale as locale.gen spells it, and its charset there (undef without
# one): glibc accepts de_DE.utf8 for de_DE.UTF-8, but locale.gen lists only
# "de_DE.UTF-8 UTF-8", and enabling "de_DE.utf8 utf8" builds nothing.
sub _locale_gen_name {
  my ($locale) = @_;
  my ($base, $charset, $modifier) = $locale =~ /\A([^.@]+)(?:\.([^@]+))?(\@.+)?\z/;
  return ($locale) unless defined $charset;
  $charset = uc $charset;
  $charset = $charset =~ /\AUTF-?8\z/           ? 'UTF-8'
           : $charset =~ /\AISO-?8859-?(\d+)\z/ ? "ISO-8859-$1"
           :                                      $charset;
  return ($base.'.'.$charset.($modifier // ''), $charset);
}

# Uncomment "<locale> <charset>" in locale.gen, append it when absent. The
# line is a validated locale (see prepare_node): no quote can end the
# shell's single quotes, and every ERE metacharacter is escaped.
sub _enable_locale_cmd {
  my ($line, $file) = @_;
  (my $re = $line) =~ s/([.\[\]()*+?{}|^\$\\])/\\$1/g;
  return 'if [ -f '.$file.' ]; then '
    .q{sed -i -E 's/^#\s*(}.$re.q{)\s*$/\1/' }.$file.'; '
    .q{grep -qE '^}.$re.q{\s*$' }.$file.q{ || echo '}.$line.q{' >> }.$file.'; fi';
}

sub _setup_ntp {
  my $synced = run "timedatectl show --property=NTPSynchronized --value 2>/dev/null", auto_die => 0;
  if (defined $synced && $synced =~ /^\s*yes\s*$/) {
    Rex::Logger::info("Clock already NTP-synchronized, not installing chrony");
    return;
  }

  Rex::Logger::info("Installing and enabling chrony for NTP");
  if (eval { pkg ["chrony"], ensure => "present"; 1 }) {
    run "systemctl enable chronyd 2>/dev/null || systemctl enable chrony 2>/dev/null", auto_die => 0;
    run "systemctl start chronyd 2>/dev/null || systemctl start chrony 2>/dev/null", auto_die => 0;
    return;
  }
  my $err = $@;
  chomp $err;
  Rex::Logger::info("chrony install failed ($err), falling back to systemd-timesyncd", 'warn');

  run "systemctl enable --now systemd-timesyncd 2>/dev/null", auto_die => 0;
  my $active = run "systemctl is-active systemd-timesyncd 2>/dev/null", auto_die => 0;
  if (defined $active && $active =~ /^\s*active\s*$/) {
    Rex::Logger::info("Using systemd-timesyncd for NTP");
    return;
  }
  # Not fatal (k42): the node works, only its clock may drift. Loud, because
  # the skew shows up later as TLS and etcd errors far from this step.
  Rex::Logger::info("NO TIME SYNCHRONIZATION IS ACTIVE on this node: chrony install "
    . "failed ($err) and systemd-timesyncd is not active (the RHEL family does not "
    . "ship it). Clock skew between nodes breaks certificate validation and etcd; "
    . "set up NTP on this host yourself", 'warn');
}

sub _disable_swap {
  Rex::Logger::info("Disabling swap");
  run "swapoff -a", auto_die => 0;
  delete_lines_matching "/etc/fstab", matching => qr/\sswap\s/;
}

sub _load_kernel_modules {
  Rex::Logger::info("Loading required kernel modules");
  run "modprobe br_netfilter", auto_die => 0;
  run "modprobe overlay", auto_die => 0;
  file "/etc/modules-load.d/kubernetes.conf", content => "br_netfilter\noverlay\n";
}

sub _configure_sysctl {
  Rex::Logger::info("Configuring kernel parameters for Kubernetes");
  file "/etc/sysctl.d/99-kubernetes.conf",
    content => join("\n",
      "net.bridge.bridge-nf-call-iptables = 1",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "net.ipv4.ip_forward = 1",
    ) . "\n";
  run "sysctl --system", auto_die => 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Node - Linux node preparation for Rancher Kubernetes distributions (RKE2/K3s)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Rex::Rancher::Node;

  # Full preparation with hostname
  prepare_node(
    hostname => 'worker-01',
    domain   => 'k8s.local',
    timezone => 'Europe/Berlin',
  );

  # Minimal preparation — hostname left unchanged; timezone UTC and
  # locale en_US.UTF-8 are still set (the defaults), chrony installed
  prepare_node();

  # Skip NTP (e.g. host is a VM with hypervisor time sync)
  prepare_node(
    hostname => 'vm-01',
    domain   => 'k8s.local',
    ntp      => 0,
  );

=head1 DESCRIPTION

L<Rex::Rancher::Node> prepares a Linux node for Rancher Kubernetes
distributions (RKE2 and K3s). The same L</prepare_node> call is verified on
Debian, Ubuntu, and RHEL/Rocky/Alma — the supported set. openSUSE Leap / SLES
is B<unverified>: the base-package step there falls through to Rex's generic
C<pkg> abstraction (zypper) and has never been exercised on real SUSE
hardware, so it is unsupported and best-effort only.

The module sets OS-level configuration that Kubernetes requires:

=over

=item * B<Swap disabled> — Kubernetes does not function correctly with swap
enabled.

=item * B<Kernel modules> — C<br_netfilter> is needed for iptables to see
bridged traffic; C<overlay> is required for containerd's overlay filesystem.

=item * B<Sysctl parameters> — IP forwarding and bridge netfilter settings
required by Kubernetes networking and CNI plugins.

=item * B<NTP> — Time skew between nodes causes certificate validation
failures and etcd instability. An already synchronized clock is left as it
is; otherwise C<chrony> is installed and started, with C<systemd-timesyncd>
as the fallback when that install fails on a host that has it
(Debian/Ubuntu). Without either, preparation goes on with a warning that no
time synchronization is active.

=back

Called automatically by L<Rex::Rancher/rancher_deploy_server> and
L<Rex::Rancher/rancher_deploy_agent>.

=head2 prepare_node

Prepare a Linux node for Kubernetes. Performs all OS-level configuration
required before installing RKE2 or K3s:

=over

=item * On Debian/Ubuntu, stop C<unattended-upgrades>, C<apt-daily.service>
and C<apt-daily-upgrade.service> (they hold the apt lock on a fresh boot)
and run C<apt-get update>. They are B<not> restarted afterwards; their
timers bring them back on schedule, C<unattended-upgrades> at the next boot.

=item * Install C<curl> and C<ca-certificates>

=item * Set hostname via C<hostnamectl> or C</etc/hostname> (optional).
A static hostname (C</etc/hostname>) that already is C<hostname> or whose
first label is C<hostname>, compared case-insensitively, is left as it is,
whatever C<domain> says: C<hostname =E<gt> 'worker-01'> keeps
C<worker-01.example.com>. The Kubernetes node name then follows the kernel
hostname, that FQDN, unless C<node_name> is set
(L<Rex::Rancher::Server/install_server>, L<Rex::Rancher::Agent/install_agent>).

=item * Add a C<127.0.1.1> entry to C</etc/hosts> when C<hostname> is given:
C<FQDN hostname> with a C<domain>, C<hostname> alone without one (then only
if no line in C</etc/hosts> names the host yet)

=item * Set timezone via C<timedatectl> or symlink (default: C<UTC>). A
timezone that is not shaped like a zoneinfo name (C<Area/City> such as
C<Europe/Berlin> or C<America/Argentina/Buenos_Aires>, C<UTC>,
C<Etc/GMT+5>: parts of letters, digits, C<_>, C<+> and C<->, each starting
with a letter, separated by C</>) dies before the host is touched. Whether
the zone exists is left to the host.

=item * Set locale via C<localectl> or C</etc/default/locale> (default: C<en_US.UTF-8>).
On Debian/Ubuntu the locale is first enabled in C</etc/locale.gen> and
generated with C<locale-gen> (skipped for C<C>/C<POSIX> and when
C<locale-gen> is not installed). The charset is written the way
C<locale.gen> spells it, so C<de_DE.utf8> enables C<de_DE.UTF-8 UTF-8>.
A locale that is not C<language_TERRITORY.charset@modifier> shaped (letters,
digits, C<_>, C<->) dies before the host is touched.

=item * NTP (default: enabled): nothing is installed when C<timedatectl>
already reports the clock as NTP-synchronized; otherwise C<chrony> is
installed and started. If the C<chrony> install fails, C<systemd-timesyncd>
is started instead where the host has it (Debian/Ubuntu; the RHEL family
does not ship it). When that is not active either, C<prepare_node> goes on
with a warning that no time synchronization is active

=item * Disable and remove swap entries from C</etc/fstab>

=item * Load C<br_netfilter> and C<overlay> kernel modules and persist to
C</etc/modules-load.d/kubernetes.conf>

=item * Write C</etc/sysctl.d/99-kubernetes.conf> with C<net.ipv4.ip_forward>,
C<net.bridge.bridge-nf-call-iptables>, and C<net.bridge.bridge-nf-call-ip6tables>,
then apply with C<sysctl --system>

=back

  prepare_node(
    hostname => 'worker-01',      # optional — short hostname
    domain   => 'k8s.local',      # optional — domain suffix for FQDN
    timezone => 'Europe/Berlin',  # optional, default: UTC
    locale   => 'en_US.UTF-8',    # optional, default: en_US.UTF-8
    ntp      => 1,                 # optional, default: 1 (ensure NTP sync)
  );

If C<hostname> is provided without C<domain>, C</etc/hosts> gets
C<127.0.1.1 hostname> unless a line already names the host (e.g. the public
IP the provider wrote), which is then left alone.

=head1 SEE ALSO

L<Rex::Rancher>, L<Rex::Rancher::Server>, L<Rex::Rancher::Agent>, L<Rex>

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
