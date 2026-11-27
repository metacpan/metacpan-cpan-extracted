# ABSTRACT: AMD driver setup for Debian 12 and 13 (experimental)

package Rex::GPU::AMD::Setup::Debian;
our $VERSION = '0.006';
use Moo;
use namespace::autoclean;

extends 'Rex::GPU::AMD::Setup::Apt';

# Sources, checked 2026-10-30:
#   ROCm 10.1 compatibility matrix (Instinct): Debian 13 kernel 6.12, Debian
#     12 kernel 6.1.0; no Radeon and no Ryzen APU support on Debian. Both
#     die here, with either driver: radeon_unsupported and
#     inbox_only_unsupported are inherited from Rex::GPU::AMD::Setup (k82);
#     install_rocm refuses their gfx targets with them too (k91).
#   amdgpu 31.60 install guide, Debian: the Ubuntu repository of
#     repo.radeon.com, suite noble for Debian 13 and jammy for Debian 12;
#     linux-headers-$K.
#   Debian's firmware for amdgpu: firmware-amd-graphics (component
#     non-free-firmware).
#   Proxmox VE 9.2 (read-only on a live host, 2026-11-04, k81): os-release
#     ID=debian VERSION_ID=13, kernel 7.0.14-20-pve with amdgpu.ko under
#     kernel/; pve-firmware Conflicts and Replaces firmware-amd-graphics, and
#     apt-get -s install firmware-amd-graphics removes proxmox-ve,
#     proxmox-default-kernel, proxmox-kernel-7.0 and pve-firmware.
#   install_rocm on the same host (read-only, 2026-11-05, k88): apt-get -s
#     install libatomic1 libquadmath0 amdrocm10.1-gfx1151 -gfx1100 -gfx942
#     from the debian13 ROCm repository: 111 new, none removed, no firmware-*
#     package. AMD's debian13 and debian12 indexes (2026-11-05): no package
#     depends on or recommends a firmware package, and the Debian 13 closure
#     (with recommends) of what they need from Debian holds none either. So
#     install_rocm asks no host_unsupported.
my %RELEASE = (
  '13' => { suite => 'noble', kernel => qr/\A6\.12\.\d+\+deb13(?:u\d+)?-amd64\z/,
            kernel_text => '6.12 (6.12.N+deb13-amd64)', rocm => 'debian13' },
  '12' => { suite => 'jammy', kernel => qr/\A6\.1\.0-\d+-amd64\z/,
            kernel_text => '6.1 (6.1.0-N-amd64)', rocm => 'debian12' },
);


sub release_data { $RELEASE{ $_[0]->os_version } }

sub host_unsupported {
  my ( $self ) = @_;
  return unless $self->package_on_disk('pve-firmware');
  return 'this is a Proxmox VE host (pve-firmware is installed): pve-firmware brings the amdgpu '
    .'firmware itself and conflicts with firmware-amd-graphics, which apt would install only by '
    .'removing proxmox-ve and the Proxmox kernel, so install_driver installs no AMD driver on '
    .'Proxmox VE (a working amdgpu of the Proxmox kernel is answered with present)';
}

sub inbox_unsupported {
  my ( $self ) = @_;
  my $row = $self->release_data
    or return 'the inbox amdgpu is supported on Debian 12 and 13 only, not '.$self->os_label;
  return if $self->kernel =~ $row->{kernel};
  return 'the inbox amdgpu is supported on '.$self->os_label." with Debian's own kernel "
    .$row->{kernel_text}.' only; this host runs '.$self->kernel;
}

sub dkms_suite {
  my ( $self ) = @_;
  my $row = $self->release_data or return;
  return $row->{suite};
}

sub dkms_unsupported {
  my ( $self ) = @_;
  my $row = $self->release_data
    or return 'amdgpu-dkms '.$self->amdgpu_release.' supports Debian 12 and 13, not '.$self->os_label;
  return if $self->kernel =~ $row->{kernel};
  return 'amdgpu-dkms '.$self->amdgpu_release.' supports '.$self->os_label.' with kernel '
    .$row->{kernel_text}.'; this host runs '.$self->kernel;
}

sub kernel_header_packages { 'linux-headers-'.$_[0]->kernel }

sub firmware_packages { 'firmware-amd-graphics' }

sub rocm_repo_dir {
  my ( $self ) = @_;
  my $row = $self->release_data or return;
  return $row->{rocm};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::AMD::Setup::Debian - AMD driver setup for Debian 12 and 13 (experimental)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

B<Experimental.> The AMD driver on Debian:

=over

=item * B<amdgpu-dkms> on Debian 12 and 13, per L</release_data>: from
C<repo.radeon.com/amdgpu/31.60/ubuntu> with C<linux-headers-$(uname -r)>,
on the release's own C<amd64> kernel only. Without an apt candidate for
either -- after an ABI bump the mirror no longer carries the running
kernel's headers -- it dies after C<apt-get update>, before any package is
installed, with the repository and its key in place; for the headers the
message says to upgrade the kernel and reboot first.

=item * B<inbox> on Debian 12 and 13, on the release's own C<amd64> kernel
only -- the same releases and kernels as C<amdgpu-dkms>, per
L</release_data> (L</inbox_unsupported>): Debian 11, testing and sid, and
any other kernel die before any change. The kernel's own C<amdgpu>, plus
C<firmware-amd-graphics> when it is not installed (in the
C<non-free-firmware> component; it dies, before installing anything, if
apt has no candidate). No package is known that adds a
missing C<amdgpu.ko> (Debian's C<amd64> kernel carries it): it dies then,
before any change. The GPUs AMD supports only with the inbox driver (the
Ryzen APUs, rows with C<driver =E<gt> 'inbox'>) are not supported on
Debian: L<Rex::GPU::AMD/install_driver> dies before any change for them,
unless their driver already works, which it answers with C<present>
(C<method =E<gt> 'dkms'> dies then too).

=item * B<No Radeon GPU> (gfx target rows with C<matrix =E<gt> 'radeon'>,
L<Rex::GPU::AMD::Hardware/targets>), with either driver: AMD's matrix lists
the Radeon GPUs only on Ubuntu and RHEL
(L<Rex::GPU::AMD::Setup/radeon_unsupported>, inherited).
L<Rex::GPU::AMD/install_driver> dies before any change for them, on every
Debian release and kernel, unless their driver already works, which it
answers with C<present>. With the Ryzen APUs refused as well, only the
Instinct GPUs -- and GPUs whose row says no C<matrix>, or that have no row
-- get C<amdgpu-dkms> or the inbox driver here.

=item * B<Not on Proxmox VE> (L</host_unsupported>): with C<pve-firmware>
installed both driver paths die before any change, also on a Debian
kernel. A working C<amdgpu> of the Proxmox kernel is answered with
C<present>, as everywhere. ROCm is not refused there:
L<Rex::GPU::AMD/install_rocm> installs no firmware package, and refuses
only what it refuses on any Debian -- the gfx targets of the Radeon GPUs
and the Ryzen APUs, which AMD's matrix does not list on Debian.

=back

=head2 release_data

The row of this Debian release (C<VERSION_ID> C<13> or C<12>), C<undef>
for another one: the C<amdgpu-dkms> suite (C<noble>, C<jammy>), the kernel
it is installed on (AMD's 6.12 and 6.1, as the release's own kernel of the
flavour C<amd64>: C<6.12.N+deb13-amd64>, C<6.1.0-N-amd64> -- not
C<cloud-amd64>, C<rt-amd64> or a backports kernel), the ROCm repository
(C<debian13>, C<debian12>). Read by the C<amdgpu-dkms> path, the inbox
path (L</inbox_unsupported>: the same releases and kernels) and
L<Rex::GPU::AMD/install_rocm>.

=head2 host_unsupported

A reason when C<pve-firmware> is on disk
(L<Rex::GPU::AMD::Setup::Apt/package_on_disk>: one C<dpkg-query>), else
C<undef>: a Proxmox VE host, which reports itself as Debian (C<ID=debian>,
C<VERSION_ID=13>). Both driver paths die on it before any change, also
with a Debian kernel booted -- the package decides, not the kernel's name.
C<pve-firmware> brings the amdgpu firmware itself and conflicts with
C<firmware-amd-graphics>; apt would remove C<proxmox-ve> and the Proxmox
kernel to install that. L<Rex::GPU::AMD/install_rocm> does not ask it: it
installs no firmware package, and runs on Proxmox VE too.

=head2 inbox_unsupported

Why the inbox driver is not supported here, or C<undef>: as
L<Rex::GPU::AMD::Setup/dkms_unsupported> does for C<amdgpu-dkms>, only
Debian 12 and 13 (L</release_data>; not Debian 11, not testing or sid,
which have no C<VERSION_ID>) with the release's own C<amd64> kernel (not
C<cloud-amd64>, C<rt-amd64>, a backports or a Proxmox kernel).

=head1 SEE ALSO

L<Rex::GPU::AMD::Setup>, L<Rex::GPU::AMD::Setup::Apt>

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
