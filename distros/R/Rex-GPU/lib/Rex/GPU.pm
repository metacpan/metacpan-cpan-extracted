# ABSTRACT: GPU detection and driver management for Rex

package Rex::GPU;
our $VERSION = '0.002';
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

  # A containerd_config typo dies here (karr #66), not after the driver
  # install and a reboot.
  my $runtime = $opts{containerd_config} // 'rke2';
  Rex::GPU::NVIDIA::_check_containerd_runtime($runtime, 'none');

  # A custom setup (setup => / set gpu_nvidia_setup, karr #34) that cannot be
  # loaded dies here, before detection installs pciutils -- on every host, not
  # only on one with a GPU.
  Rex::GPU::NVIDIA->custom_setup($opts{setup});

  my $gpus = gpu_detect();

  if ($gpus->{nvidia} && @{$gpus->{nvidia}}) {
    my @compute = grep { $_->{compute} } @{$gpus->{nvidia}};
    if (@compute) {
      Rex::Logger::info("CUDA-capable NVIDIA GPU: " . $_->{name}) for @compute;
      # Every compute GPU (karr #33): the driver has to fit all of them.
      # NVSwitch (karr #23): passed only when there is one, so every other
      # host gets exactly the call it got before.
      my $nvswitch = $gpus->{nvswitch} // [];
      Rex::Logger::info("NVSwitch host (".scalar(@$nvswitch)." NVSwitch): NVIDIA Fabric "
        ."Manager is installed with the driver") if @$nvswitch;
      Rex::GPU::NVIDIA::install_driver(
        reboot => ($opts{reboot} ? 1 : 0),
        gpus   => \@compute,
        ( map { defined $opts{$_} ? ( $_ => $opts{$_} ) : () } qw( setup requirement ) ),
        ( @$nvswitch ? ( nvswitches => $nvswitch ) : () ),
      );
      Rex::GPU::NVIDIA::install_container_toolkit();
      Rex::GPU::NVIDIA::generate_cdi_specs();

      if ($runtime ne 'none') {
        Rex::GPU::NVIDIA::configure_containerd($runtime);
      }

      # The full check, toolkit included, once the toolkit is there (karr
      # #42); install_driver checks only the driver.
      Rex::GPU::NVIDIA::verify_nvidia();
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

version 0.002

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
Only CUDA-capable NVIDIA GPUs trigger driver installation, decided by the GPU
generation read from the PCI device ID, not by name or PCI class: Maxwell and
newer count (GeForce MX, GT and GTX 9xx included), Kepler and older are
skipped with a warning at any PCI class. See L</gpu_setup>.

=item 2. B<NVIDIA driver installation> — Distribution-appropriate packages
via DKMS for kernel-version independence, chosen so one driver fits every
detected GPU. Nouveau is blacklisted and the initramfs is regenerated. An
NVIDIA vGPU guest without a working driver dies before any driver package
is installed (see L</gpu_setup>).

=item 3. B<NVIDIA Container Toolkit> — Installs C<nvidia-container-toolkit>
from the official NVIDIA repository for all supported distributions, unless
it is already installed (then it is left as it is, not upgraded; see
L<Rex::GPU::NVIDIA/install_container_toolkit>).

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

=back

The verified target set is the RKE2 Linux family above. B<openSUSE Leap / SLES
is unverified and unsupported> — SUSE is not a deploy target for the
GPU-on-Rancher pipeline.

GPUs tested include the NVIDIA RTX 4000 SFF Ada Generation (PCI class
C<0302>, datacenter compute profile).

This module requires L<Rex::LibSSH> (or SFTP) on the connection backend.
Hetzner servers do not enable the SFTP subsystem by default; use
C<set connection =E<gt> "LibSSH"> in your Rexfile.

L<Rex::LibSSH> version C<0.004> and later verify the server's host key against
C<known_hosts> by default. A freshly provisioned host has no entry yet, so the
B<first> connection fails with C<host key is not in known_hosts and
strict_hostkeycheck is on>. There are two ways to handle this:

=over

=item * B<Recommended> (keeps host-key verification) — scan the key into
C<known_hosts> before deploying:

  ssh-keyscan <host> >> ~/.ssh/known_hosts

The bundled C<eg/Rexfile> and C<eg/hetzner-gpu.pl> do this in a
C<before 'ALL'> hook.

=item * B<Disable the check Rexfile-wide> — for first-contact provisioning;
a deliberate security tradeoff:

  use Rex -feature => ['1.4', 'disable_strict_host_key_checking'];

=back

=head1 FUNCTIONS

=head2 gpu_detect

Detect GPU hardware on the remote host by scanning PCI devices. Installs
C<pciutils> only if C<lspci> is not on the host's C<PATH> (dies if it still
is not afterwards), then parses C<lspci -nn> output. See
L<Rex::GPU::Detect/detect>.

Returns a hashref with detected GPUs grouped by vendor, plus the HGX
NVSwitch chips under C<nvswitch>:

  my $gpus = gpu_detect();
  # {
  #   nvidia => [
  #     {
  #       name      => "AD104GL [RTX 4000 SFF Ada Generation]",
  #       vendor    => "nvidia",
  #       pci_class => "0302",   # 0300 = VGA, 0302 = 3D/compute
  #       compute   => 1,        # 1 if CUDA-capable
  #       device_id => "27b0",
  #       subsystem_vendor_id => "10de",
  #       subsystem_id        => "16fa",
  #       vgpu      => 0,        # 1 for an NVIDIA vGPU guest device
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
  #   nvswitch => [],            # HGX NVSwitch chips, see Rex::GPU::Detect
  # }

Virtual display devices (virtio, QEMU, VMware, VirtualBox) are skipped. If
they are the only display devices all three arrays (C<nvidia>, C<amd>,
C<nvswitch>) are empty; a real card passed through next to one (vfio-pci,
cloud GPU VM) is still detected. An NVIDIA vGPU guest device is told
apart from a physical or passed-through card by its PCI subsystem ID, read
with another read-only C<lspci> only on hosts with an NVIDIA GPU: C<vgpu =E<gt> 1>
and C<vgpu_type> (see L<Rex::GPU::Detect/NVIDIA vGPU guests>). See
L<Rex::GPU::Detect> for details on the classification logic.

=head2 gpu_setup

Detect GPUs and run the full installation pipeline: NVIDIA driver, Container
Toolkit, CDI spec generation, and containerd runtime configuration. This is
the single call needed to make a node GPU-ready for Kubernetes.

Every CUDA-capable NVIDIA GPU detected (name and PCI device ID) is passed
to L<Rex::GPU::NVIDIA/install_driver> as C<gpus>, and one driver is chosen
that can drive them all -- the intersection of what each GPU needs (see
L<Rex::GPU::NVIDIA::Requirement>). Blackwell-architecture silicon
(B200/GB200/B300, GeForce RTX 50xx, RTX PRO Blackwell, the GB10 / NVIDIA DGX
Spark) has no proprietary kernel module at all, on x86_64 and aarch64 alike:
Ubuntu gets the C<-open> driver package variant instead of the default
C<-server> one, Debian 12 and 13 NVIDIA's CUDA-repository open-module driver
instead of Debian's C<non-free> one (which cannot drive them); on any other
Debian release it dies before any driver package is installed. A pre-Turing GPU
(Maxwell/Pascal/Volta, e.g. the V100, a GeForce GT 1030 or GTX 980) gets the
proprietary 580-branch driver on Ubuntu, RHEL and openSUSE, Debian's
C<non-free> driver on Debian 12 and 13. A host whose GPUs are all Turing to
Hopper gets the same driver as before.

Which GPUs count as CUDA-capable is decided by generation, not by marketing
name (see L<Rex::GPU::Detect/NVIDIA compute classification>): every Maxwell
or newer GPU does, GeForce MX, GT and GTX 9xx included. A Kepler-or-older
GPU at any PCI class (GeForce GT 710, GTX 780, Quadro K4000, and the class
C<0302> Tesla K80/K40/K20) is detected with C<compute =E<gt> 0> and skipped
with a warning: no driver is installed for it, and it does not stop the
installation for a newer GPU on the same host. GPUs that cannot share one
driver (a V100 next to a B200) make C<gpu_setup> die before any driver
package is installed, unless a working driver is already installed.

On an NVIDIA vGPU guest (C<vgpu =E<gt> 1> in the L</gpu_detect> result:
Azure NVadsA10 v5, AWS G6f, ...) the GPU needs NVIDIA's licensed vGPU guest
driver, which Rex::GPU does not install. If that driver already works
(C<nvidia-smi -L> lists the GPU and C<libcuda.so.1> is in the linker cache)
C<gpu_setup> goes on as on any host with a working driver: container
toolkit, CDI specs, containerd. If not, it dies in
L<Rex::GPU::NVIDIA/install_driver> before any driver package is installed,
naming the vGPU type -- also when a GPU that is not a vGPU sits next to it.

On an HGX baseboard with NVSwitches (HGX-2, HGX A100, HGX H100/H200:
C<nvswitch> in the L</gpu_detect> result is not empty) the NVSwitches are
passed as C<nvswitches>, and NVIDIA Fabric Manager is installed with the
driver at exactly its version and C<nvidia-fabricmanager.service> enabled --
without it CUDA does not initialise on those hosts. A distro source that has
no Fabric Manager is not used (Debian's C<non-free>; Debian 12/13 takes
NVIDIA's CUDA repository instead, Debian 11 and openSUSE die before any
driver package is installed). If the driver is already installed, Fabric
Manager is added only when the host's own package sources offer it at exactly the loaded
driver's version (asked after an C<apt-get update> on Debian/Ubuntu);
otherwise it warns and installs nothing. No package source is added and the
driver is not touched either way. See the
C<nvswitches> option of L<Rex::GPU::NVIDIA/install_driver>. Hosts without
NVSwitch are unchanged.
HGX B200/B300 have no NVSwitch on the host PCI bus (C<nvswitch> is empty
there); they are recognised by the GPU device IDs, and C<gpu_setup>
installs Fabric Manager with their driver the same way, then the NVLink
Subnet Manager C<nvlsm>, C<infiniband-diags> and C<libibumad> (unversioned,
from NVIDIA's CUDA repository -- on Ubuntu added for this, pinned to
C<nvlsm> alone), loads C<ib_umad>, warns on a kernel older than 5.17
(except on the RHEL family), and after the start checks that every GPU
reports C<Fabric State: Completed> -- a loud warning if not, never a die.
With the driver already installed, the missing ones of these packages are
installed from the host's own package sources (after an C<apt-get update> on
Debian/Ubuntu; no source is added, one not offered only warns) and
C<ib_umad> is loaded.
Where no C<nvlsm> source is known it dies before any driver package is installed. GB200/GB300 NVL72 compute
trays need no Fabric Manager (it runs on the NVLink switch trays); an info
line notes that multi-node NVLink needs C<nvidia-imex>, which is not set
up either. See the C<nvswitches> option of L<Rex::GPU::NVIDIA/install_driver>.

Each die named above comes from L<Rex::GPU::NVIDIA::Setup/plan>, known
without a refreshed package index: by then no package source has been
added and nothing has been installed, except C<pciutils> when
L</gpu_detect> found no C<lspci> on the host.

After the last step L<Rex::GPU::NVIDIA/verify_nvidia> checks the result --
kernel module, C<nvidia-smi -L>, container toolkit -- and logs a warning for
anything missing (e.g. the module before the first reboot); it never dies.
It runs on every call with a CUDA-capable GPU, also when the driver was
already installed.

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

=item C<rke2> (default) — registers the NVIDIA runtime additively under
C</var/lib/rancher/rke2/agent/etc/containerd/>: a no-op if RKE2 already wired
it natively, otherwise a C<config-v3.toml.d/> drop-in (modern, config v3) or a
base-extending C<config.toml.tmpl> (legacy, config v2). The RKE2-generated base
config is never replaced.

=item C<k3s> — same logic as C<rke2>, under C</var/lib/rancher/k3s/...>; K3s
and RKE2 share the same containerd config mechanism

=item C<containerd> — runs C<nvidia-ctk runtime configure --runtime=containerd>
for a standalone containerd installation

=item C<none> — skip containerd configuration entirely (driver and toolkit are
still installed)

=back

Any other value makes C<gpu_setup> die before detection, naming the valid
values -- even on a host without a GPU.

=item C<reboot>

If true, the host is rebooted after driver installation and the function
waits (up to 5 minutes, polling every 5 seconds) for it to come back before
continuing with toolkit installation and containerd configuration. Default: C<0>.

Rebooting is required on the first deployment if the C<nouveau> open-source
driver was previously loaded, because nouveau must be unloaded before the
NVIDIA driver can bind to the GPU.

=item C<setup>

B<Experimental.> The L<Rex::GPU::NVIDIA::Setup> class (a name) or object
that installs the driver, instead of the one Rex::GPU picks for the OS --
typically a subclass of one of the built-in ones, kept in your project's
C<lib/> (see L<Rex::GPU::NVIDIA::Setup/WRITING YOUR OWN SETUP>). Without
it, C<set gpu_nvidia_setup =E<gt> 'My::GPU::Setup'> in the Rexfile does the
same for every call; this option wins over it. A class that cannot be loaded
or is not a Setup makes C<gpu_setup> die before anything is done on the
host, even on a host without a GPU. Passed to
L<Rex::GPU::NVIDIA/install_driver>.

=item C<requirement>

B<Experimental.> An extra constraint on the driver, e.g.
C<< { kernel_module =E<gt> 'open', min_branch =E<gt> 580 } >> (keys
C<kernel_module>, C<min_branch>, C<max_branch>), B<intersected> with what
the detected GPUs need: it can narrow the choice but never override a
GPU's hard limit. If no driver meets both, C<gpu_setup> dies before the
driver install changes the host. Passed to
L<Rex::GPU::NVIDIA/install_driver>.

=back

Neither option changes anything for a caller that does not pass it; in
particular L<Rex::Rancher>'s C<gpu =E<gt> 1> passes neither, and picks up a
custom setup through C<set gpu_nvidia_setup>.

Returns the result of L<Rex::GPU::Detect/detect> — a hashref with C<nvidia>,
C<amd> and C<nvswitch> array keys.

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
