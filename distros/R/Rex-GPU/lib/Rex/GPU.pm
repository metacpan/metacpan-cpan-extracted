# ABSTRACT: GPU detection and driver management for Rex

package Rex::GPU;
our $VERSION = '0.006';
use v5.14.4;
use warnings;

use Scalar::Util qw( blessed );

use Rex::GPU::Detect;
use Rex::GPU::NVIDIA;
use Rex::GPU::AMD ();

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  gpu_detect
  gpu_setup
);



sub gpu_detect {
  my ( $class, %opts ) = _invocant(@_) ? @_ : ( __PACKAGE__, @_ );
  my $detect = $class->detect_class($opts{detect});
  return $class->_step($detect, 'Rex::GPU::Detect', 'detect');
}


sub _check_connection {
  my ( $class ) = @_;
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
  my ( $class, %opts ) = _invocant(@_) ? @_ : ( __PACKAGE__, @_ );

  $class->_step($class, __PACKAGE__, '_check_connection');

  # A class of the user's (nvidia => / detect => / amd =>, set
  # gpu_nvidia_class / gpu_detect_class / gpu_amd_class, karr #71, k1) that
  # cannot be loaded dies here, before anything touches the host.
  my $nvidia = $class->nvidia_class($opts{nvidia});
  $class->detect_class($opts{detect});
  my $amd = $class->amd_class($opts{amd});

  # A containerd_config typo dies here (karr #66), not after the driver
  # install and a reboot.
  my $runtime = $opts{containerd_config} // 'rke2';
  $nvidia->_check_containerd_runtime($runtime, 'none');

  # A custom setup (setup => / set gpu_nvidia_setup, karr #34) that cannot be
  # loaded dies here, before detection installs pciutils -- on every host, not
  # only on one with a GPU.
  $nvidia->custom_setup($opts{setup});

  my $gpus = $class->_step($class, __PACKAGE__, 'gpu_detect',
    ( defined $opts{detect} ? ( detect => $opts{detect} ) : () ));

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
      $class->_step($nvidia, 'Rex::GPU::NVIDIA', 'install_driver',
        reboot => ($opts{reboot} ? 1 : 0),
        gpus   => \@compute,
        ( map { defined $opts{$_} ? ( $_ => $opts{$_} ) : () } qw( setup requirement ) ),
        ( @$nvswitch ? ( nvswitches => $nvswitch ) : () ),
      );
      $class->_step($nvidia, 'Rex::GPU::NVIDIA', 'install_container_toolkit');
      $class->_step($nvidia, 'Rex::GPU::NVIDIA', 'generate_cdi_specs');

      if ($runtime ne 'none') {
        $class->_step($nvidia, 'Rex::GPU::NVIDIA', 'configure_containerd', $runtime);
      }

      # The full check, toolkit included, once the toolkit is there (karr
      # #42); install_driver checks only the driver.
      $class->_step($nvidia, 'Rex::GPU::NVIDIA', 'verify_nvidia');
    }
  }

  # AMD (karr k1): the amdgpu driver for every ROCm-capable AMD GPU -- an
  # integrated one (APU) only with amd_integrated => 1. Every other one is
  # named in a warning with the reason. Unknown (compute undef) gets nothing.
  if ($gpus->{amd} && @{$gpus->{amd}}) {
    my @install;
    for my $gpu (@{$gpus->{amd}}) {
      my $why = !defined $gpu->{compute} ? 'no hardware row for it, compute unknown'
        : !$gpu->{compute}               ? 'not ROCm-capable'
        : $gpu->{integrated} && !$opts{amd_integrated}
          ? 'integrated GPU (APU); pass amd_integrated => 1 to install for it'
        : undef;
      if (defined $why) {
        Rex::Logger::info("AMD GPU detected: $gpu->{name} -- no driver installed: $why", "warn");
        next;
      }
      Rex::Logger::info("ROCm-capable AMD GPU: " . $gpu->{name});
      push @install, $gpu;
    }
    if (@install) {
      {
        # k90: a die for GPUs whose rows disagree (APU + amdgpu-dkms GPU,
        # amd_integrated => 1) names gpu_setup's ways out, not method/gpus.
        local $Rex::GPU::AMD::GPU_SETUP = 1;
        # k104: "Nothing was changed on the host" is install_driver's own;
        # gpu_detect (pciutils) and the NVIDIA steps may have changed the host
        # before it, so here it is said for the AMD GPUs. k110: so are
        # "Nothing was installed" (last) and "No driver package was installed"
        # (last, or before ";") of the dies after apt-get update -- the NVIDIA
        # steps may have installed their driver. Any other die (an object,
        # another sentence) is passed on as it is.
        eval {
          $class->_step($amd, 'Rex::GPU::AMD', 'install_driver',
            gpus   => \@install,
            reboot => ($opts{reboot} ? 1 : 0),
          );
          1;
        } or do {
          my $error = $@;
          my $noun = @install > 1 ? 'GPUs' : 'GPU';
          unless (ref $error) {
            $error =~ s/ Nothing was changed on the host\n\z/ Nothing was changed for the AMD $noun\n/;
            $error =~ s/ Nothing was installed\n\z/ Nothing was installed for the AMD $noun\n/;
            $error =~ s/ No driver package was installed(?=;|\n\z)/ No driver package was installed for the AMD $noun/;
          }
          die $error;
        };
      }
      $class->_step($amd, 'Rex::GPU::AMD', 'verify_amd', gpus => \@install);
    }
  }

  return $gpus;
}


sub nvidia_class {
  my ( $class, $nvidia ) = @_;
  return Rex::GPU::NVIDIA->configured_class($nvidia);
}


sub detect_class {
  my ( $class, $detect ) = @_;
  return Rex::GPU::Detect->configured_class($detect);
}


sub amd_class {
  my ( $class, $amd ) = @_;
  return Rex::GPU::AMD->configured_class($amd);
}

# One step of the pipeline. With the built-in class ($target eq $base) it is
# called through its function name, with exactly the arguments it always got:
# Rex::Rancher's tests, kubernetes-ocp's and t/ replace those globs
# (*Rex::GPU::NVIDIA::install_driver, *Rex::GPU::gpu_detect, ...) and record
# @_. A class of the user's gets a method call instead.
sub _step {
  my ( $class, $target, $base, $name, @args ) = @_;
  return $target eq $base ? $base->can($name)->(@args) : $target->$name(@args);
}

# Called as a method (Rex::GPU->gpu_setup, My::GPU->gpu_setup): the invocant,
# a class name or object that isa Rex::GPU. Called as a function
# (gpu_setup(...) from a Rexfile, Rex::GPU::gpu_setup(...)): undef -- a first
# argument such as 'containerd_config' is no package of ours, and nothing is
# loaded to find out.
sub _invocant {
  my ( $first ) = @_;
  return unless defined $first && ( !ref $first || blessed $first );
  return $first if eval { $first->isa(__PACKAGE__) };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU - GPU detection and driver management for Rex

=head1 VERSION

version 0.006

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

=item 4. B<CDI spec generation> — Makes C<nvidia.com/gpu=all> and
C<management.nvidia.com/gpu=all> resolvable, writing under C</etc/cdi> only
what C<nvidia-ctk cdi list> does not already show, so the Kubernetes device
plugin can enumerate GPU resources without privileged container access and
the GPU Operator validator finds its management device (see
L<Rex::GPU::NVIDIA/generate_cdi_specs>).

=item 5. B<Containerd runtime configuration> — Injects the NVIDIA runtime
into the containerd config for the target Kubernetes distribution.

=back

AMD (B<experimental>): a ROCm-capable discrete AMD GPU gets the AMD kernel
driver C<amdgpu> -- the distribution kernel's own, or AMD's C<amdgpu-dkms>
-- through L<Rex::GPU::AMD>; steps 3 to 5 are NVIDIA's only. ROCm itself is
a separate call, L<Rex::GPU::AMD/install_rocm>. See L</gpu_setup>.

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

Each function also works as a class method, C<Rex::GPU-E<gt>gpu_setup(...)>
or C<My::GPU-E<gt>gpu_setup(...)> for a subclass of your own (experimental),
with the same arguments; called as a function it runs as C<Rex::GPU>. See
L</CLASSES OF YOUR OWN>.

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
  #       name       => "AMD GPU [1002:1586]",   # pci.ids name if the host's knows it
  #       vendor     => "amd",
  #       pci_class  => "0380",   # 0300, 0302, 0380 or 1200
  #       slot       => "0000:95:00.0",
  #       device_id  => "1586",
  #       gfx_target => "gfx1151",
  #       compute    => 1,        # 1 ROCm-capable, 0 not, undef unknown
  #       integrated => 1,        # 1 APU, 0 discrete, undef unknown
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
and C<vgpu_type> (see L<Rex::GPU::Detect/NVIDIA vGPU guests>). On hosts
with an AMD GPU one more read-only command reads the AMD driver state, for
the GPU's gfx target (see L<Rex::GPU::Detect/AMD compute classification>).
See L<Rex::GPU::Detect> for details on the classification logic.

  my $gpus = gpu_detect(detect => 'My::GPU::Detect');

B<Experimental.> The one option, C<detect>, names the L<Rex::GPU::Detect>
subclass that detects instead (see L</detect_class>); without it
C<set gpu_detect_class> or C<Rex::GPU::Detect> does. The built-in
L<Rex::GPU::Detect::Sysfs> is one: it reads C</sys/bus/pci/devices>
instead of C<lspci>, installs nothing, and returns the same shape without
product names (C<compute> is C<undef> where only a name could decide).

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
Hopper gets the same driver as before where that driver's branch is new
enough: Ada and Hopper need 520 or newer, and a single Turing to Hopper ID
that NVIDIA listed first in a later branch needs that one (up to 580; see
L<Rex::GPU::NVIDIA::Requirement/generations>). On Debian 11 (C<non-free>
470) and a Debian release without a known C<non-free> branch, a host with
one of them dies before any driver package is installed; on Debian 12 and
13 an ID newer than the C<non-free> branch (535 and 550; on 12 e.g. the RTX
4070 SUPER or the H200) gets NVIDIA's CUDA-repository open-module driver, as
Blackwell does.

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

One die comes after the install instead: on Debian and the RHEL family's
open driver, whose package names carry no branch, the branch that
got installed is checked against what the GPUs need when that has a bound
(a C<min_branch>/C<max_branch>: Ada, Hopper, Blackwell, GH200,
Maxwell/Pascal/Volta and the Turing/Ampere IDs with a row of their own, or a
C<requirement> with one). A branch that does not fit -- e.g. a
C<nvidia-kernel-open-dkms> held at 550 on a Blackwell host -- makes
C<gpu_setup> die with the driver packages and
their package source B<installed>, before Fabric Manager, the nouveau
blacklist, the initramfs and the reboot, and before the container toolkit
(L<Rex::GPU::NVIDIA::Setup/verify_driver_branch>). A held older branch that
still fits passes.

After the last step L<Rex::GPU::NVIDIA/verify_nvidia> checks the result --
kernel module, C<nvidia-smi -L>, container toolkit -- and logs a warning for
anything missing (e.g. the module before the first reboot); it never dies.
It runs on every call with a CUDA-capable GPU, also when the driver was
already installed.

B<Experimental.> Every ROCm-capable AMD GPU (C<compute =E<gt> 1> in the
L</gpu_detect> result) that is not integrated is passed to
L<Rex::GPU::AMD/install_driver> as C<gpus>, with C<reboot>, which makes the
AMD kernel driver C<amdgpu> usable for ROCm -- or does nothing if it already
is (one read-only command) -- and then to L<Rex::GPU::AMD/verify_amd>,
which logs a warning for anything missing and never dies. An integrated GPU
(C<integrated =E<gt> 1>: an APU such as the Ryzen AI Max) is passed only
with C<amd_integrated =E<gt> 1>. Every AMD GPU not passed gets a warning
naming why: unknown (no hardware row, C<compute =E<gt> undef>), not
ROCm-capable, or integrated. Neither ROCm itself
(L<Rex::GPU::AMD/install_rocm>) nor any container runtime or CDI setup for
AMD is part of C<gpu_setup>.

The AMD steps come last. A die of L<Rex::GPU::AMD/install_driver> ends
C<gpu_setup> without L<Rex::GPU::AMD/verify_amd>. Most of them come before
C<install_driver> changes the host (see there), but not before what
C<gpu_setup> did up to then: L</gpu_detect> (which installs C<pciutils> if
it found no C<lspci>), and on a host with a CUDA-capable NVIDIA GPU every
NVIDIA step above -- the driver step (with C<reboot>, the reboot after a
driver install), the container toolkit, the CDI specs, the containerd
configuration unless C<containerd_config> is C<none>, and
L<Rex::GPU::NVIDIA/verify_nvidia>. None of that is undone. So where the
message of such a die ends with C<Nothing was changed on the host> (as it
does from C<install_driver> called directly), C<gpu_setup> ends it with
C<Nothing was changed for the AMD GPU> instead (C<GPUs> when it passed
several), also for an C<amd> class of your own. The same goes for the dies
after C<apt-get update> (a package without a candidate, a failed C<dnf
repoquery>): C<Nothing was installed> at the end becomes C<Nothing was
installed for the AMD GPU>, and C<No driver package was installed> -- at
the end or before a C<;> -- C<No driver package was installed for the AMD
GPU> (C<GPUs> likewise).

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

If true, C<gpu_setup> may reboot the host (when: below) and waits for it:
20 seconds, then up to 60 reconnects 5 seconds apart (over 5 minutes in
all) until C<echo ok> answers from the new boot (a changed C<boot_id>,
where it was readable before); if it does not come back, C<gpu_setup>
dies. Default: C<0>.

NVIDIA: the host is rebooted right after the driver is installed -- not
when a working driver was already there -- before the toolkit installation
and containerd configuration go on. Rebooting is required on the first
deployment if the C<nouveau> open-source driver was previously loaded,
because nouveau must be unloaded before the NVIDIA driver can bind to the
GPU.

AMD, with C<inbox> and C<dkms> alike: the host is rebooted only if
C<amdgpu> did not already work (then nothing is installed and nothing is
rebooted) and loading it is not enough -- if C<amdgpu> was not loaded
before, C<modprobe amdgpu> is tried first; if it was loaded but not
usable, the host is rebooted without trying it. After that reboot the
driver must be usable, or C<gpu_setup> dies. Without C<reboot> a warning
says to reboot, and C<gpu_setup> goes on to L<Rex::GPU::AMD/verify_amd>.
A host with an NVIDIA and an AMD GPU can be rebooted twice.

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

=item C<nvidia>

B<Experimental.> A subclass of L<Rex::GPU::NVIDIA> (a class name) that
runs every NVIDIA step -- L<Rex::GPU::NVIDIA/install_driver>, the container
toolkit, CDI, containerd, verification -- as class methods, so it can
override any of them or any helper they call. Without it, C<set
gpu_nvidia_class =E<gt> 'My::GPU::NVIDIA'> in the Rexfile does the same for
every call, a plain function call such as C<install_driver(...)> included;
this option wins over it. See L</nvidia_class>.

=item C<detect>

B<Experimental.> A subclass of L<Rex::GPU::Detect> (a class name) that
detects the GPUs instead, passed to L</gpu_detect>; without it C<set
gpu_detect_class>. See L</detect_class>. C<detect =E<gt>
'Rex::GPU::Detect::Sysfs'> detects from sysfs, without C<lspci> and
without installing C<pciutils>; a GPU it leaves at C<compute =E<gt> undef>
(no generation row, no name to judge) gets no driver here.

=item C<amd>

B<Experimental.> A subclass of L<Rex::GPU::AMD> (a class name) that runs
the AMD steps -- L<Rex::GPU::AMD/install_driver> and
L<Rex::GPU::AMD/verify_amd> -- as class methods. Without it, C<set
gpu_amd_class =E<gt> 'My::GPU::AMD'> in the Rexfile does the same for every
call; this option wins over it. See L</amd_class>.

=item C<amd_integrated>

B<Experimental.> If true, a ROCm-capable integrated AMD GPU (an APU, e.g.
the Ryzen AI Max C<gfx1151>) gets the driver too. Default: C<0>, an
integrated GPU is skipped with a warning. AMD supports the Ryzen APUs only
with the inbox driver; next to a GPU that needs C<amdgpu-dkms> (one
C<amdgpu> drives every GPU of a host), unless C<amdgpu> already works for
all of them, L<Rex::GPU::AMD/install_driver> dies before it changes the
host -- but after the NVIDIA steps, if any (see above) -- naming the ways
out: leave C<amd_integrated> off (the other GPUs get the driver, the APU is
skipped with a warning), or call L<Rex::GPU::AMD/install_driver> directly
with C<method> or C<gpus>.

=back

A class of C<setup>, C<nvidia>, C<detect> or C<amd> that cannot be loaded
or does not extend its base class makes C<gpu_setup> die before anything is
done on the host, even on a host without a GPU.

None of these options changes anything for a caller that does not pass
it; in particular L<Rex::Rancher>'s C<gpu =E<gt> 1> passes none, and picks
up a custom setup through C<set gpu_nvidia_setup> and custom classes
through C<set gpu_nvidia_class> / C<set gpu_detect_class> /
C<set gpu_amd_class>. The AMD driver install itself needs no option: it
runs for every ROCm-capable discrete AMD GPU, C<gpu =E<gt> 1> included.

Returns the result of L<Rex::GPU::Detect/detect> — a hashref with C<nvidia>,
C<amd> and C<nvswitch> array keys.

Dies if the connection backend is neither LibSSH nor SFTP-capable.

=head2 nvidia_class

  my $class = Rex::GPU->nvidia_class($nvidia_option);

B<Experimental.> The L<Rex::GPU::NVIDIA> class L</gpu_setup> installs with:
C<$nvidia_option> (its C<nvidia> option) if defined, else C<set
gpu_nvidia_class>, else C<Rex::GPU::NVIDIA>. See
L<Rex::GPU::NVIDIA/configured_class>; croaks before anything touches the
host for a class that cannot be loaded or is not a L<Rex::GPU::NVIDIA>.

=head2 detect_class

  my $class = Rex::GPU->detect_class($detect_option);

B<Experimental.> The L<Rex::GPU::Detect> class L</gpu_detect> (and so
L</gpu_setup>) detects with: C<$detect_option> (their C<detect> option) if
defined, else C<set gpu_detect_class>, else C<Rex::GPU::Detect>. See
L<Rex::GPU::Detect/configured_class>.

=head2 amd_class

  my $class = Rex::GPU->amd_class($amd_option);

B<Experimental.> The L<Rex::GPU::AMD> class L</gpu_setup> installs the AMD
driver with: C<$amd_option> (its C<amd> option) if defined, else C<set
gpu_amd_class>, else C<Rex::GPU::AMD>. See
L<Rex::GPU::AMD/configured_class>; croaks before anything touches the host
for a class that cannot be loaded or is not a L<Rex::GPU::AMD>.

=head1 CLASSES OF YOUR OWN

B<Experimental>, like L<Rex::GPU::NVIDIA::Setup>. C<Rex::GPU>,
L<Rex::GPU::Detect>, L<Rex::GPU::NVIDIA> and L<Rex::GPU::AMD> are plain
packages whose
functions are also class methods: every step and every private helper is
called through the class it runs as, so a subclass overrides one without
copying the rest.

  # lib/My/GPU/NVIDIA.pm, next to the Rexfile
  package My::GPU::NVIDIA;
  use parent 'Rex::GPU::NVIDIA';
  sub generate_cdi_specs {
    my ( $class, @args ) = @_;
    $class->next::method(@args);     # or SUPER::, never the function name
    # ... your extra step
  }
  1;

  # Rexfile
  set gpu_nvidia_class => 'My::GPU::NVIDIA';   # or gpu_setup(nvidia => ...)

A function call (C<install_driver(...)>, C<Rex::GPU::NVIDIA::verify_nvidia()>,
C<configure_containerd('rke2')>) is passed on unchanged, as a method, to
the configured class (L<Rex::GPU::NVIDIA/configured_class>,
L<Rex::GPU::Detect/configured_class>). An override must therefore call the
built-in step as a method (C<next::method>, C<SUPER::>), not by its
function name, which with C<set gpu_nvidia_class> comes back to it. L</gpu_setup> calls each step
through its function name while the built-in class is in use, so code that
replaces C<Rex::GPU::NVIDIA::install_driver> and friends sees the same
arguments as before.

=head1 SEE ALSO

L<Rex>, L<Rex::LibSSH>, L<Rex::GPU::Detect>, L<Rex::GPU::NVIDIA>,
L<Rex::GPU::AMD>, L<Rex::Rancher>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
