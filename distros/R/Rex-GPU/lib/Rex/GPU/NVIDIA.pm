# ABSTRACT: NVIDIA GPU driver and container toolkit management

package Rex::GPU::NVIDIA;
our $VERSION = '0.001';
use v5.14.4;
use warnings;

use Rex::Commands::File;
use Rex::Commands::Gather;
use Rex::Commands::Pkg;
use Rex::Commands::Run;
use Rex::Logger;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_driver
  install_container_toolkit
  configure_containerd
  verify_nvidia
  generate_cdi_specs
);


sub install_driver {
  my (%opts) = @_;

  my $os = operating_system();
  my $running_kernel = run "uname -r";
  chomp $running_kernel;

  Rex::Logger::info("Installing NVIDIA drivers on $os (kernel $running_kernel)");

  if (is_debian()) {
    _install_driver_debian($os, $running_kernel);
  }
  elsif (is_redhat()) {
    _install_driver_redhat($os, $running_kernel);
  }
  elsif (is_suse()) {
    _install_driver_suse($os, $running_kernel);
  }
  else {
    die "Unsupported OS for NVIDIA driver installation: $os\n";
  }

  _blacklist_nouveau();

  if ($opts{reboot}) {
    _reboot_and_wait();
  }
  else {
    run "modprobe nvidia", auto_die => 0;
  }

  verify_nvidia();

  Rex::Logger::info("NVIDIA driver installation complete");
}


sub install_container_toolkit {
  my $os = operating_system();

  Rex::Logger::info("Installing NVIDIA Container Toolkit");

  if (is_debian()) {
    _install_toolkit_debian();
  }
  elsif (is_redhat()) {
    _install_toolkit_redhat();
  }
  elsif (is_suse()) {
    _install_toolkit_suse();
  }
  else {
    die "Unsupported OS for NVIDIA Container Toolkit: $os\n";
  }

  Rex::Logger::info("NVIDIA Container Toolkit installed");
}


sub configure_containerd {
  my ($runtime) = @_;
  $runtime //= 'rke2';

  return unless can_run("nvidia-container-runtime");

  Rex::Logger::info("Configuring containerd for NVIDIA GPU (runtime: $runtime)");

  if ($runtime eq 'rke2' || $runtime eq 'k3s') {
    _configure_containerd_rke2();
  }
  elsif ($runtime eq 'containerd') {
    _configure_containerd_standalone();
  }
  else {
    die "Unknown containerd runtime: $runtime\n";
  }

  Rex::Logger::info("Containerd configured with NVIDIA runtime");
}


sub verify_nvidia {
  Rex::Logger::info("Verifying NVIDIA installation...");
  my $ok = 1;

  my $lsmod = run "lsmod | grep '^nvidia '", auto_die => 0;
  if ($? != 0 || !$lsmod) {
    Rex::Logger::info("nvidia kernel module not loaded (reboot may be needed)", "warn");
    $ok = 0;
  }
  else {
    Rex::Logger::info("  [ok] nvidia kernel module loaded");
  }

  my $smi = run "nvidia-smi -L 2>&1", auto_die => 0;
  chomp $smi if defined $smi;
  if (defined $smi && $smi =~ /GPU \d+:/) {
    Rex::Logger::info("  [ok] $smi");
  }
  else {
    Rex::Logger::info("nvidia-smi not working: " . ($smi // 'no output'), "warn");
    $ok = 0;
  }

  if (can_run("nvidia-ctk")) {
    Rex::Logger::info("  [ok] nvidia-container-toolkit installed");
  }
  else {
    Rex::Logger::info("nvidia-container-toolkit not found", "warn");
    $ok = 0;
  }

  unless ($ok) {
    Rex::Logger::info("GPU verification incomplete — some features may not work until reboot", "warn");
  }

  return $ok;
}

# ============================================================
#  Debian / Ubuntu
# ============================================================

sub _install_driver_debian {
  my ($os, $running_kernel) = @_;

  my $arch = run "dpkg --print-architecture", auto_die => 0;
  chomp $arch;

  # Ensure non-free repos are enabled (Debian only, Ubuntu has restricted by default)
  if ($os ne 'Ubuntu') {
    _enable_debian_nonfree();
  }

  my @packages = ("linux-headers-$running_kernel");

  if ($os eq 'Ubuntu') {
    push @packages, "linux-headers-generic";
    # Ubuntu: use server variant for K8s, auto-detect latest available version.
    # Do NOT add nvidia-smi: on Ubuntu 24.04 it is a virtual package with no
    # installation candidate — it is pulled in automatically by the driver metapackage.
    my $latest = run "apt-cache search '^nvidia-driver-[0-9].*-server\$' 2>/dev/null | sort -t- -k3 -n | tail -1 | awk '{print \$1}'",
      auto_die => 0;
    chomp $latest if $latest;
    # Filter out *-open variants from auto-detect (use regular server driver)
    $latest = undef if $latest && $latest =~ /-open$/;
    push @packages, ($latest || "nvidia-driver-570-server");
  }
  else {
    # Debian: just the running kernel's headers (sufficient for DKMS) + driver
    # Do NOT install linux-headers-$arch meta-package — it pulls in a new kernel
    # image whose post-install scripts (grub, initramfs) can return non-zero
    push @packages, "nvidia-driver", "nvidia-smi";
  }

  Rex::Logger::info("  Installing: " . join(", ", @packages));
  # Stop automatic apt services before installing — on a fresh Hetzner boot,
  # unattended-upgrades and apt-daily hold /var/lib/dpkg/lock-frontend, which
  # causes apt-get to fail immediately even with DPkg::Lock::Timeout set.
  run "systemctl stop unattended-upgrades apt-daily.service apt-daily-upgrade.service 2>/dev/null || true",
    auto_die => 0;
  run "apt-get -o DPkg::Lock::Timeout=120 update -q", auto_die => 0;

  # Use apt-get directly: Rex::Pkg::Apt fails when apt exits non-zero due to
  # post-install scripts (DKMS build, grub update, initramfs). Verify via dpkg -l.
  my $pkg_str = join(" ", @packages);
  run "DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 install -y $pkg_str", auto_die => 0;

  # On Ubuntu the driver package is e.g. nvidia-driver-590-server; on Debian it is
  # nvidia-driver. Check whichever name we actually installed.
  my $driver_pkg = ($os eq 'Ubuntu') ? $packages[-1] : 'nvidia-driver';
  my $check = run "dpkg -l $driver_pkg 2>/dev/null | grep -q '^ii'", auto_die => 0;
  die "$driver_pkg not installed after apt-get install — check apt output\n"
    if $? != 0;
}

sub _enable_debian_nonfree {
  # Add contrib non-free non-free-firmware to all deb lines
  my $sources = run "cat /etc/apt/sources.list 2>/dev/null", auto_die => 0;
  return unless $sources;

  if ($sources !~ /non-free/) {
    Rex::Logger::info("  Enabling non-free repos for NVIDIA drivers");
    run "sed -i 's/^deb \\(.*\\) main/deb \\1 main contrib non-free non-free-firmware/' /etc/apt/sources.list",
      auto_die => 0;
  }
}

# ============================================================
#  RHEL / Rocky / AlmaLinux / CentOS Stream
# ============================================================

sub _install_driver_redhat {
  my ($os, $running_kernel) = @_;

  my $major = _rhel_major_version();

  # Enable required repos
  Rex::Logger::info("  Enabling EPEL and extra repos...");
  pkg ["epel-release"], ensure => "present";

  if ($major >= 9) {
    run "dnf config-manager --set-enabled crb 2>/dev/null || true", auto_die => 0;
  }
  else {
    run "dnf config-manager --set-enabled powertools 2>/dev/null || true", auto_die => 0;
  }

  # Add NVIDIA CUDA repo
  my $distro = "rhel$major";
  Rex::Logger::info("  Adding NVIDIA CUDA repo ($distro)...");
  run "dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$distro/x86_64/cuda-$distro.repo 2>/dev/null",
    auto_die => 0;
  run "dnf clean expire-cache", auto_die => 0;

  # Kernel headers
  my @packages;
  if ($major >= 9) {
    @packages = ("kernel-devel-matched", "kernel-headers");
  }
  else {
    @packages = ("kernel-devel-$running_kernel", "kernel-headers");
  }

  # Driver packages — different for v10 (no module streams, dkms variant)
  if ($major >= 10) {
    push @packages, "kmod-nvidia-open-dkms", "nvidia-driver", "nvidia-driver-cuda";
  }
  else {
    run "dnf module enable nvidia-driver:open-dkms -y 2>/dev/null || true", auto_die => 0;
    push @packages, "nvidia-open";
  }

  Rex::Logger::info("  Installing: " . join(", ", @packages));

  # Use run() directly: Rex::Pkg::Dnf fails when dnf exits non-zero due to
  # DKMS post-install scripts (kernel module build). Verify via rpm -q instead.
  my $pkg_str = join(" ", @packages);
  run "dnf install -y $pkg_str", auto_die => 0;

  my $check = run "rpm -q nvidia-driver 2>&1", auto_die => 0;
  die "nvidia-driver not installed after dnf install — check dnf output\n"
    if $? != 0;
}

sub _rhel_major_version {
  # Rex::Commands::Gather::operating_system_version() strips dots,
  # so "10.1" becomes "101". Use operating_system_release() for the raw
  # version string and extract the major version ourselves.
  my $release = Rex::Commands::Gather::operating_system_release();
  $release =~ /^(\d+)/;
  return $1 + 0;
}

# ============================================================
#  openSUSE Leap
# ============================================================

sub _install_driver_suse {
  my ($os, $running_kernel) = @_;

  my $version = operating_system_version();
  my $major = int($version);

  # Remove any stale NVIDIA packages first — avoids kmp/userspace version mismatch
  # caused by libnvidia-ml/libnvidia-cfg from the standard OSS non-free repo lagging
  # behind the NVIDIA GFX repo packages.
  Rex::Logger::info("  Removing any existing NVIDIA packages...");
  run q{rpm -e $(rpm -qa | grep -E '^(nvidia|libnvidia)' | grep -v 'container') 2>/dev/null || true},
    auto_die => 0;

  # Add NVIDIA GFX repo (use direct baseurls — zypper cannot parse yum .repo files)
  if ($major >= 16) {
    Rex::Logger::info("  Adding NVIDIA GFX repo (suse16)...");
    run "zypper rr nvidia-gfx 2>/dev/null || true", auto_die => 0;
    run "zypper addrepo --refresh https://download.nvidia.com/opensuse/leap/16.0/ nvidia-gfx 2>/dev/null",
      auto_die => 0;
  }
  else {
    my $leap_version = sprintf("%.1f", $version / 10);  # 156 -> 15.6
    Rex::Logger::info("  Adding NVIDIA GFX repo (opensuse15, Leap $leap_version)...");
    run "zypper rr nvidia-gfx 2>/dev/null || true", auto_die => 0;
    run "zypper addrepo --refresh https://download.nvidia.com/opensuse/leap/$leap_version/ nvidia-gfx 2>/dev/null",
      auto_die => 0;
  }
  run "zypper --gpg-auto-import-keys refresh nvidia-gfx 2>/dev/null", auto_die => 0;

  # Use the meta package — it co-installs kmp-default + userspace at the same version,
  # preventing the split that causes "Driver/library version mismatch" with nvidia-smi.
  # Pre-signed kmp packages don't need kernel-devel/headers.
  my $meta_pkg = $major >= 16
    ? "nvidia-open-driver-G07-signed-kmp-meta"
    : "nvidia-open-driver-G06-signed-kmp-meta";

  Rex::Logger::info("  Installing $meta_pkg...");
  run "zypper install -y $meta_pkg", auto_die => 0;

  # Lock the OSS non-free standalone packages so future zypper updates don't
  # pull in a stale libnvidia-ml / libnvidia-cfg and cause a mismatch again.
  run "zypper addlock libnvidia-ml libnvidia-cfg 2>/dev/null || true", auto_die => 0;
}

# ============================================================
#  Nouveau blacklisting
# ============================================================

sub _blacklist_nouveau {
  file "/etc/modprobe.d/blacklist-nouveau.conf",
    content => "blacklist nouveau\noptions nouveau modeset=0\n";

  if (is_debian()) {
    run "update-initramfs -u 2>/dev/null", auto_die => 0;
  }
  elsif (is_redhat()) {
    run "dracut --force 2>/dev/null", auto_die => 0;
  }
  elsif (is_suse()) {
    run "dracut --force 2>/dev/null", auto_die => 0;
  }
}

# ============================================================
#  Container toolkit installation
# ============================================================

sub _install_toolkit_debian {
  pkg ["curl", "gnupg"], ensure => "present";

  run "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null",
    auto_die => 0;

  file "/etc/apt/sources.list.d/nvidia-container-toolkit.list",
    content => 'deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/$(ARCH) /' . "\n";

  run "apt-get -o DPkg::Lock::Timeout=120 update -q", auto_die => 0;
  # DPkg::Lock::Timeout=120: wait for apt-daily.timer lock that fires after reboot.
  run "DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 install -y nvidia-container-toolkit", auto_die => 0;
  my $check = run "dpkg -l nvidia-container-toolkit 2>/dev/null | grep -q '^ii'", auto_die => 0;
  die "nvidia-container-toolkit not installed\n" if $? != 0;
}

sub _install_toolkit_redhat {
  run "curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo",
    auto_die => 0;
  run "dnf clean expire-cache", auto_die => 0;
  run "dnf install -y nvidia-container-toolkit", auto_die => 0;
  my $check = run "rpm -q nvidia-container-toolkit 2>&1", auto_die => 0;
  die "nvidia-container-toolkit not installed\n" if $? != 0;
}

sub _install_toolkit_suse {
  # The .repo file URL is yum/dnf format — zypper needs the baseurl directly.
  # Remove any stale entry (possibly added with the wrong URL) before re-adding.
  my $arch = run "uname -m", auto_die => 0;
  chomp $arch;
  $arch ||= 'x86_64';

  run "zypper rr nvidia-container-toolkit 2>/dev/null || true", auto_die => 0;
  run "rpm --import https://nvidia.github.io/libnvidia-container/gpgkey 2>/dev/null",
    auto_die => 0;
  run "zypper addrepo --refresh https://nvidia.github.io/libnvidia-container/stable/rpm/$arch nvidia-container-toolkit 2>/dev/null",
    auto_die => 0;
  run "zypper --gpg-auto-import-keys refresh nvidia-container-toolkit 2>/dev/null",
    auto_die => 0;

  run "zypper install -y nvidia-container-toolkit", auto_die => 0;
}

# ============================================================
#  Containerd configuration
# ============================================================

sub _configure_containerd_rke2 {
  file "/var/lib/rancher/rke2/agent/etc/containerd", ensure => 'directory';
  file "/var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl",
    content => "imports = [\"/etc/containerd/conf.d/*.toml\"]\nversion = 2\n";

  _write_nvidia_containerd_config();
}

sub _configure_containerd_standalone {
  run "nvidia-ctk runtime configure --runtime=containerd 2>&1", auto_die => 0;
  run "systemctl restart containerd 2>/dev/null", auto_die => 0;
}

sub _write_nvidia_containerd_config {
  file "/etc/containerd/conf.d", ensure => 'directory';
  file "/etc/containerd/conf.d/99-nvidia.toml", content => <<'TOML';
version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
            BinaryName = "/usr/bin/nvidia-container-runtime"
TOML
}

# ============================================================
#  CDI spec generation
# ============================================================


sub generate_cdi_specs {
  Rex::Logger::info("Generating NVIDIA CDI specs...");
  run "mkdir -p /etc/cdi", auto_die => 0;
  run "nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml 2>/dev/null", auto_die => 0;
  Rex::Logger::info("  [ok] CDI specs written to /etc/cdi/nvidia.yaml");
}

# ============================================================
#  Reboot
# ============================================================

sub _reboot_and_wait {
  Rex::Logger::info("Rebooting host to activate NVIDIA driver (replacing nouveau)...");

  # Schedule reboot 2 s from now so the run() call can return cleanly
  run "nohup sh -c 'sleep 2 && shutdown -r now' >/dev/null 2>&1 &", auto_die => 0;

  # Wait long enough for the system to actually go down
  sleep 20;

  # Poll until SSH comes back (up to 5 minutes)
  my $conn = Rex::get_current_connection()->{conn};
  my $back = 0;
  for my $i (1..60) {
    eval { $conn->disconnect() };
    eval { $conn->reconnect() };
    unless ($@) {
      # Verify we can actually run a command
      my $test = eval { run "echo ok", auto_die => 0; "ok" };
      if (defined $test && $test =~ /ok/) {
        Rex::Logger::info("  Host is back online (after ~" . ($i * 5 + 20) . "s)");
        $back = 1;
        last;
      }
    }
    Rex::Logger::info("  Waiting for host to come back... ($i/60)");
    sleep 5;
  }

  die "Host did not come back after reboot\n" unless $back;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA - NVIDIA GPU driver and container toolkit management

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Rex::GPU::NVIDIA;

  # Step 1: Install driver (with reboot on first deploy)
  install_driver(reboot => 1);

  # Step 2: Install NVIDIA Container Toolkit
  install_container_toolkit();

  # Step 3: Generate CDI specs for the device plugin
  generate_cdi_specs();

  # Step 4: Configure containerd for Kubernetes
  configure_containerd('rke2');   # 'rke2', 'k3s', or 'containerd'

  # Verify the current installation status
  my $ok = verify_nvidia();

=head1 DESCRIPTION

L<Rex::GPU::NVIDIA> manages the full NVIDIA software stack needed to run
GPU-accelerated workloads in Kubernetes: driver installation, the Container
Toolkit, CDI spec generation, and containerd runtime configuration.

Each step is OS-aware and handles Debian/Ubuntu, RHEL/Rocky/CentOS, and
openSUSE Leap without further configuration.

=head2 Driver installation

Drivers are installed via DKMS, so they survive kernel upgrades without
needing reinstallation. The C<nouveau> open-source driver is blacklisted
and the initramfs is regenerated to prevent it from loading at boot.

On Debian, C<contrib>, C<non-free>, and C<non-free-firmware> components
are added to C</etc/apt/sources.list> automatically if not already present.

On RHEL/Rocky/AlmaLinux/CentOS Stream, the NVIDIA CUDA repository is added
and the open-kernel DKMS variant is used. For RHEL 10+ the module streams
approach is not available; C<kmod-nvidia-open-dkms> is installed directly.

On openSUSE Leap, the signed kmp-meta package (C<nvidia-open-driver-G06-signed-kmp-meta>
for Leap 15.x, C<nvidia-open-driver-G07-signed-kmp-meta> for Leap 16.x) is
used to ensure the kernel module and userspace libraries are always at the
same version. Stale OSS non-free packages are removed before installation
and locked afterwards to prevent C<nvidia-smi> from reporting a
C<Driver/library version mismatch>.

=head2 Container Toolkit

C<nvidia-container-toolkit> is installed from the official NVIDIA GitHub
package repository (L<https://nvidia.github.io/libnvidia-container/>).

=head2 CDI specs

Container Device Interface specifications are written to C</etc/cdi/nvidia.yaml>
by C<nvidia-ctk cdi generate>. CDI lets the Kubernetes device plugin
enumerate GPU resources without requiring privileged container access.

=head2 Containerd configuration

For RKE2 and K3s, the NVIDIA runtime is registered via a drop-in snippet at
C</etc/containerd/conf.d/99-nvidia.toml>, imported via the distribution's
C<config.toml.tmpl> mechanism. For standalone containerd,
C<nvidia-ctk runtime configure> is used.

Supported distributions:

=over

=item * Debian 11 (bullseye), 12 (bookworm), 13 (trixie)

=item * Ubuntu 22.04 (jammy), 24.04 (noble)

=item * RHEL / Rocky Linux / AlmaLinux 8, 9, 10 — CentOS Stream 9, 10

=item * openSUSE Leap 15.6, 16.0

=back

Tested on Hetzner dedicated servers with NVIDIA RTX 4000 SFF Ada Generation.

=head2 install_driver

Install NVIDIA GPU drivers appropriate for the detected OS using DKMS.
Blacklists the C<nouveau> driver and rebuilds the initramfs so the blacklist
takes effect on next boot.

After installation (and after reboot, if C<reboot =E<gt> 1>), calls
L</verify_nvidia> to confirm the kernel module loaded correctly.

Dies if the detected OS is not supported.

Options:

=over

=item C<reboot>

If true, the host is rebooted immediately after driver installation.
The function waits up to 5 minutes for the host to come back (polling
every 5 seconds via SSH reconnect), then continues with verification.
Default: C<0>.

Rebooting is required on the first deployment when the C<nouveau>
open-source driver was previously loaded, because nouveau must be
unloaded before the NVIDIA kernel module can bind to the device.

=back

  install_driver();              # install only, load module without reboot
  install_driver(reboot => 1);   # install, reboot, verify

=head2 install_container_toolkit

Install the NVIDIA Container Toolkit (C<nvidia-container-toolkit> package)
from the official NVIDIA package repository at
L<https://nvidia.github.io/libnvidia-container/>.

The repository GPG key is imported and the package repository is registered
before installing. On Debian/Ubuntu the signed APT source list is written;
on RHEL the C<.repo> file is fetched via C<curl>; on openSUSE Leap the
base repository URL is added directly (zypper cannot parse RPM C<.repo>
files directly).

Dies if the OS is not supported or if installation fails.

=head2 configure_containerd($runtime)

Configure the containerd runtime to use the NVIDIA container runtime.
The C<nvidia-container-runtime> binary must already be installed
(L</install_container_toolkit> provides it); if it is not present this
function returns immediately without error.

C<$runtime> selects how containerd is configured:

=over

=item C<rke2> or C<k3s> (default: C<rke2>)

Creates C</var/lib/rancher/rke2/agent/etc/containerd/> and writes a
C<config.toml.tmpl> that imports snippets from C</etc/containerd/conf.d/>.
Then writes C</etc/containerd/conf.d/99-nvidia.toml> which registers the
NVIDIA runtime as C<io.containerd.runc.v2> with
C<BinaryName=/usr/bin/nvidia-container-runtime>.

This approach is used by both RKE2 and K3s because they share the same
containerd include mechanism.

=item C<containerd>

Calls C<nvidia-ctk runtime configure --runtime=containerd> and restarts
the C<containerd> systemd service. Suitable for standalone (non-Rancher)
containerd installations.

=back

=head2 verify_nvidia

Verify the current NVIDIA installation by checking three things:

=over

=item 1. C<nvidia> kernel module is loaded (C<lsmod | grep nvidia>)

=item 2. C<nvidia-smi -L> reports at least one GPU

=item 3. C<nvidia-ctk> binary is available (Container Toolkit present)

=back

Returns C<1> if all checks pass, C<0> if any check fails. A warning is
logged for each failure; the function does not die. A partial installation
(e.g. driver installed but host not yet rebooted) emits a summary warning
noting that features may not work until reboot.

=head2 generate_cdi_specs

Generate CDI (Container Device Interface) specifications for all detected
NVIDIA GPUs by running C<nvidia-ctk cdi generate>. CDI allows the Kubernetes
NVIDIA device plugin to enumerate GPU resources without requiring a privileged
container.

Writes output to C</etc/cdi/nvidia.yaml>. The C</etc/cdi/> directory is
created if it does not exist.

This step must be run after L</install_container_toolkit> (which provides
C<nvidia-ctk>) and, on first deploy, after the reboot that activates the
NVIDIA kernel module (so the tool can enumerate physical devices).

=head1 SEE ALSO

L<Rex::GPU>, L<Rex::GPU::Detect>,
L<https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-gpu/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
