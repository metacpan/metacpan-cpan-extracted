# ABSTRACT: Linux node preparation for Rancher Kubernetes distributions (RKE2/K3s)

package Rex::Rancher::Node;
our $VERSION = '0.001';
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

sub _set_hostname {
  my ($hostname, $fqdn) = @_;
  Rex::Logger::info("Setting hostname to $hostname");
  if (can_run("hostnamectl")) {
    run "hostnamectl set-hostname $hostname", auto_die => 0;
  }
  else {
    file "/etc/hostname", content => "$hostname\n";
    run "hostname $hostname", auto_die => 0;
  }
}

sub _set_hosts_entry {
  my ($hostname, $fqdn) = @_;
  Rex::Logger::info("Configuring /etc/hosts for $fqdn");
  host_entry $fqdn,
    ensure  => "present",
    ip      => "127.0.1.1",
    aliases => [$hostname];
}

sub _set_timezone {
  my ($timezone) = @_;
  Rex::Logger::info("Setting timezone to $timezone");
  if (can_run("timedatectl")) {
    run "timedatectl set-timezone $timezone", auto_die => 0;
  }
  else {
    run "ln -sf /usr/share/zoneinfo/$timezone /etc/localtime", auto_die => 0;
    file "/etc/timezone", content => "$timezone\n";
  }
}

sub _set_locale {
  my ($locale) = @_;
  Rex::Logger::info("Setting locale to $locale");
  if (can_run("localectl")) {
    run "localectl set-locale LANG=$locale", auto_die => 0;
  }
  else {
    file "/etc/default/locale", content => "LANG=$locale\n";
  }
}

sub _setup_ntp {
  Rex::Logger::info("Installing and enabling chrony for NTP");
  pkg ["chrony"], ensure => "present";
  run "systemctl enable chronyd 2>/dev/null || systemctl enable chrony 2>/dev/null", auto_die => 0;
  run "systemctl start chronyd 2>/dev/null || systemctl start chrony 2>/dev/null", auto_die => 0;
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

version 0.001

=head1 SYNOPSIS

  use Rex::Rancher::Node;

  # Full preparation with hostname
  prepare_node(
    hostname => 'worker-01',
    domain   => 'k8s.local',
    timezone => 'Europe/Berlin',
  );

  # Minimal preparation — leave hostname and locale at OS defaults
  prepare_node();

  # Skip NTP (e.g. host is a VM with hypervisor time sync)
  prepare_node(
    hostname => 'vm-01',
    domain   => 'k8s.local',
    ntp      => 0,
  );

=head1 DESCRIPTION

L<Rex::Rancher::Node> prepares a Linux node for Rancher Kubernetes
distributions (RKE2 and K3s). It is distribution-agnostic — the same
L</prepare_node> call works on Debian, Ubuntu, RHEL/Rocky/Alma, and
openSUSE Leap.

The module sets OS-level configuration that Kubernetes requires:

=over

=item * B<Swap disabled> — Kubernetes does not function correctly with swap
enabled.

=item * B<Kernel modules> — C<br_netfilter> is needed for iptables to see
bridged traffic; C<overlay> is required for containerd's overlay filesystem.

=item * B<Sysctl parameters> — IP forwarding and bridge netfilter settings
required by Kubernetes networking and CNI plugins.

=item * B<NTP> — Time skew between nodes causes certificate validation
failures and etcd instability. C<chrony> is installed and started.

=back

Called automatically by L<Rex::Rancher/rancher_deploy_server> and
L<Rex::Rancher/rancher_deploy_agent>.

=head2 prepare_node

Prepare a Linux node for Kubernetes. Performs all OS-level configuration
required before installing RKE2 or K3s:

=over

=item * Install C<curl> and C<ca-certificates>

=item * Set hostname via C<hostnamectl> or C</etc/hostname> (optional)

=item * Add FQDN entry to C</etc/hosts> (when both C<hostname> and C<domain> given)

=item * Set timezone via C<timedatectl> or symlink (default: C<UTC>)

=item * Set locale via C<localectl> or C</etc/default/locale> (default: C<en_US.UTF-8>)

=item * Install and start C<chrony> for NTP synchronisation (default: enabled)

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
    ntp      => 1,                 # optional, default: 1 (enable chrony)
  );

If C<hostname> is provided without C<domain>, the hostname is still set
but no C</etc/hosts> entry is written.

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
