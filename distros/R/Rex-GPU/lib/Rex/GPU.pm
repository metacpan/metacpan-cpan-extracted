# ABSTRACT: GPU detection and driver management for Rex

package Rex::GPU;
our $VERSION = '0.001';
use v5.14.4;
use warnings;

use Rex::GPU::Detect;
use Rex::GPU::NVIDIA;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  gpu_detect
  gpu_setup
);



sub gpu_detect {
  return Rex::GPU::Detect::detect();
}


sub _check_connection {
  my $conn = Rex::get_current_connection() or return;
  return if Rex::is_local();

  my $type = eval { $conn->{conn}->get_connection_type() } // '';
  return if $type eq 'LibSSH';

  my $sftp = eval { Rex::get_sftp() };
  return if $sftp && eval { $sftp->stat('/'); 1 };

  die "This host has no SFTP subsystem and you are not using the LibSSH "
    . "connection backend.\n"
    . "Add 'set connection => \"LibSSH\"' to your Rexfile and install "
    . "Rex::LibSSH to deploy to SFTP-less hosts.\n";
}

sub gpu_setup {
  my (%opts) = @_;

  _check_connection();

  my $gpus = gpu_detect();

  if ($gpus->{nvidia} && @{$gpus->{nvidia}}) {
    my @compute = grep { $_->{compute} } @{$gpus->{nvidia}};
    if (@compute) {
      Rex::Logger::info("CUDA-capable NVIDIA GPU: " . $compute[0]->{name});
      Rex::GPU::NVIDIA::install_driver(reboot => ($opts{reboot} ? 1 : 0));
      Rex::GPU::NVIDIA::install_container_toolkit();
      Rex::GPU::NVIDIA::generate_cdi_specs();

      my $runtime = $opts{containerd_config} // 'rke2';
      if ($runtime ne 'none') {
        Rex::GPU::NVIDIA::configure_containerd($runtime);
      }
    }
  }

  if ($gpus->{amd} && @{$gpus->{amd}}) {
    Rex::Logger::info("AMD GPU detected — driver support not yet implemented", "warn");
  }

  return $gpus;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU - GPU detection and driver management for Rex

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Rex::GPU;

  # Detect GPUs only — returns a hashref
  my $gpus = gpu_detect();
  if (@{ $gpus->{nvidia} }) {
    say "NVIDIA GPU: ", $gpus->{nvidia}[0]{name};
  }

  # Full GPU setup for an RKE2 cluster (detect + drivers + toolkit + containerd)
  gpu_setup(
    containerd_config => 'rke2',   # 'rke2', 'k3s', 'containerd', or 'none'
    reboot            => 1,        # reboot after driver install (first deploy)
  );

  # For a K3s cluster
  gpu_setup(containerd_config => 'k3s');

  # Just drivers + toolkit, no containerd config
  gpu_setup(containerd_config => 'none');

=head1 DESCRIPTION

L<Rex::GPU> provides GPU detection and driver management for L<Rex>. It
automates the complete software stack needed to make NVIDIA GPUs available
to workloads running in a Kubernetes cluster.

The full pipeline, as executed by L</gpu_setup>:

=over

=item 1. B<GPU detection> — PCI class code scan via C<lspci -nn> to identify
NVIDIA and AMD hardware, filtering out virtual GPUs (virtio, QEMU, VMware).
Only CUDA-capable NVIDIA GPUs (RTX, Quadro, Tesla, PCI class C<0302>) trigger
driver installation.

=item 2. B<NVIDIA driver installation> — Distribution-appropriate packages
via DKMS for kernel-version independence. Nouveau is blacklisted and the
initramfs is regenerated.

=item 3. B<NVIDIA Container Toolkit> — Installs C<nvidia-container-toolkit>
from the official NVIDIA repository for all supported distributions.

=item 4. B<CDI spec generation> — Writes C</etc/cdi/nvidia.yaml> so the
Kubernetes device plugin can enumerate GPU resources without privileged
container access.

=item 5. B<Containerd runtime configuration> — Injects the NVIDIA runtime
into the containerd config for the target Kubernetes distribution.

=back

Tested on Hetzner dedicated servers (bare metal) running:

=over

=item * Debian 11 (bullseye), 12 (bookworm), 13 (trixie)

=item * Ubuntu 22.04 (jammy), 24.04 (noble)

=item * RHEL / Rocky Linux / AlmaLinux 8, 9, 10 — CentOS Stream 9, 10

=item * openSUSE Leap 15.6, 16.0

=back

GPUs tested include the NVIDIA RTX 4000 SFF Ada Generation (PCI class
C<0302>, datacenter compute profile).

This module requires L<Rex::LibSSH> (or SFTP) on the connection backend.
Hetzner servers do not enable the SFTP subsystem by default; use
C<set connection =E<gt> "LibSSH"> in your Rexfile.

=head1 FUNCTIONS

=head2 gpu_detect

Detect GPU hardware on the remote host by scanning PCI devices. Installs
C<pciutils> if not already present, then parses C<lspci -nn> output.

Returns a hashref with detected GPUs grouped by vendor:

  my $gpus = gpu_detect();
  # {
  #   nvidia => [
  #     {
  #       name      => "NVIDIA RTX 4000 SFF Ada Generation",
  #       vendor    => "nvidia",
  #       pci_class => "0302",   # 0300 = VGA, 0302 = 3D/compute
  #       compute   => 1,        # 1 if CUDA-capable
  #     }
  #   ],
  #   amd => [
  #     {
  #       name      => "Radeon RX 7900 XTX",
  #       vendor    => "amd",
  #       pci_class => "0300",
  #       compute   => 0,        # always 0 (AMD not yet supported)
  #     }
  #   ],
  # }

Virtual GPUs (virtio, QEMU, VMware, VirtualBox) are detected and silently
skipped — both arrays will be empty. See L<Rex::GPU::Detect> for details on
the classification logic.

=head2 gpu_setup

Detect GPUs and run the full installation pipeline: NVIDIA driver, Container
Toolkit, CDI spec generation, and containerd runtime configuration. This is
the single call needed to make a node GPU-ready for Kubernetes.

AMD GPUs are detected and logged but not yet supported (a warning is emitted).

  gpu_setup(
    containerd_config => 'rke2',  # containerd integration target
    reboot            => 1,       # reboot after driver install
  );

Options:

=over

=item C<containerd_config>

Which containerd configuration variant to write. Controls where the NVIDIA
runtime snippet is placed:

=over

=item C<rke2> (default) — writes to
C</var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl> and drops a
snippet in C</etc/containerd/conf.d/99-nvidia.toml>

=item C<k3s> — same as C<rke2>; K3s and RKE2 share the same containerd
config include mechanism

=item C<containerd> — runs C<nvidia-ctk runtime configure --runtime=containerd>
for a standalone containerd installation

=item C<none> — skip containerd configuration entirely (driver and toolkit are
still installed)

=back

=item C<reboot>

If true, the host is rebooted after driver installation and the function
waits (up to 5 minutes, polling every 5 seconds) for it to come back before
continuing with toolkit installation and containerd configuration. Default: C<0>.

Rebooting is required on the first deployment if the C<nouveau> open-source
driver was previously loaded, because nouveau must be unloaded before the
NVIDIA driver can bind to the GPU.

=back

Returns the result of L<Rex::GPU::Detect/detect> — a hashref with C<nvidia>
and C<amd> array keys.

Dies if the connection backend is neither LibSSH nor SFTP-capable.

=head1 SEE ALSO

L<Rex>, L<Rex::LibSSH>, L<Rex::GPU::Detect>, L<Rex::GPU::NVIDIA>,
L<Rex::Rancher>

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
