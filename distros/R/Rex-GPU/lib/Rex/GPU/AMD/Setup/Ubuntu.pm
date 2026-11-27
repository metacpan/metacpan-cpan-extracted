# ABSTRACT: AMD driver setup for Ubuntu 22.04, 24.04 and 26.04 (experimental)

package Rex::GPU::AMD::Setup::Ubuntu;
our $VERSION = '0.006';
use Moo;
use namespace::autoclean;

extends 'Rex::GPU::AMD::Setup::Apt';

# Sources, checked 2026-10-30:
#   ROCm 10.1 compatibility matrix
#     https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html
#     Instinct (amdgpu-dkms): 26.04.1 GA 7.0, 24.04.5 GA 6.8, 22.04.5 GA 5.15;
#     Radeon (amdgpu-dkms):   26.04.1 GA 7.0, 24.04.5 HWE 7.0, 22.04.5 HWE 6.8;
#     Ryzen APUs: "Inbox kernel driver in supported Ubuntu version", 26.04.1 GA
#     7.0 and 24.04.5 HWE 7.0 only. AMD's Ryzen install page names 24.04.4
#     with the OEM kernel 6.14 instead (hardware curator, k1). The matrix is
#     followed, so an APU on 6.14 dies before any change. The Radeon list
#     binds every GPU of the Radeon table (matrix => 'radeon'), whatever
#     the method (k82): a Radeon on 24.04 GA 6.8 or 22.04 GA 5.15 dies.
#     install_rocm binds the Radeon and Ryzen APU targets the same way (k91).
#   amdgpu 31.60 install guide (instinct.docs.amd.com/projects/amdgpu-docs,
#     docs-31.60.0): suites resolute/noble/jammy; linux-headers-$K, and on
#     24.04/22.04 linux-modules-extra-$K.
#   synapse (Ubuntu 24.04, 7.0.0-42-generic), 2026-10-31: no package
#     linux-modules-extra-7.0.0-42-generic (amdgpu.ko is in linux-modules), so
#     linux-modules-extra-$K is installed only where apt has a candidate.
#   Firmware: linux-firmware-amd-graphics (noble-updates, resolute), split off
#     linux-firmware, which depends on it from that version on; an older
#     linux-firmware still carries the files -- either one installed suffices.
my %RELEASE = (
  '26.04' => { suite => 'resolute', dkms => [qw( 7.0 )], inbox_only => [qw( 7.0 )],
               radeon => [qw( 7.0 )],
               firmware => [qw( linux-firmware-amd-graphics linux-firmware )],
               modules_extra => 0, rocm => 'ubuntu2604' },
  '24.04' => { suite => 'noble', dkms => [qw( 6.8 7.0 )], inbox_only => [qw( 7.0 )],
               radeon => [qw( 7.0 )],
               firmware => [qw( linux-firmware-amd-graphics linux-firmware )],
               modules_extra => 1, rocm => 'ubuntu2404' },
  '22.04' => { suite => 'jammy', dkms => [qw( 5.15 6.8 )], inbox_only => [],
               radeon => [qw( 6.8 )],
               firmware => [qw( linux-firmware )],
               modules_extra => 1, rocm => 'ubuntu2204' },
);


sub release_data { $RELEASE{ $_[0]->os_version } }

sub kernel_series {
  my ( $self ) = @_;
  return $self->kernel =~ /\A(\d+\.\d+)\.\d+-\d+-generic\z/ ? $1 : undef;
}

sub dkms_suite {
  my ( $self ) = @_;
  my $row = $self->release_data or return;
  return $row->{suite};
}

sub dkms_unsupported {
  my ( $self ) = @_;
  my $row = $self->release_data
    or return 'amdgpu-dkms '.$self->amdgpu_release.' supports Ubuntu 22.04, 24.04 and 26.04, not '
      .$self->os_label;
  return $self->_kernel_unsupported('amdgpu-dkms '.$self->amdgpu_release, $row->{dkms});
}

sub inbox_only_unsupported {
  my ( $self ) = @_;
  my $row = $self->release_data;
  return $self->SUPER::inbox_only_unsupported unless $row && @{ $row->{inbox_only} };
  my $why = $self->_kernel_unsupported('AMD (inbox driver only)', $row->{inbox_only}) // return;
  return $why.' -- '.$self->inbox_only_supported;
}

sub radeon_unsupported {
  my ( $self ) = @_;
  my $row = $self->release_data;
  return $self->SUPER::radeon_unsupported unless $row && @{ $row->{radeon} };
  my $why = $self->_kernel_unsupported('AMD (Radeon GPUs)', $row->{radeon}) // return;
  return $why.' -- '.$self->radeon_supported;
}

sub _kernel_unsupported {
  my ( $self, $what, $series ) = @_;
  my $have = $self->kernel_series;
  return if defined $have && grep { $_ eq $have } @$series;
  return $what.' supports '.$self->os_label.' with kernel '.join(' or ', @$series)
    .' (-generic); this host runs '.$self->kernel;
}

sub kernel_header_packages { 'linux-headers-'.$_[0]->kernel }

sub optional_packages {
  my ( $self ) = @_;
  my $row = $self->release_data or return;
  return $row->{modules_extra} ? 'linux-modules-extra-'.$self->kernel : ();
}

sub inbox_module_packages { $_[0]->optional_packages }

sub firmware_packages {
  my ( $self ) = @_;
  my $row = $self->release_data or return;
  return @{ $row->{firmware} };
}

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

Rex::GPU::AMD::Setup::Ubuntu - AMD driver setup for Ubuntu 22.04, 24.04 and 26.04 (experimental)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

B<Experimental.> The AMD driver on Ubuntu:

=over

=item * B<amdgpu-dkms> on 22.04, 24.04 and 26.04 with a C<-generic> kernel
of AMD's matrix, per L</release_data>: from
C<repo.radeon.com/amdgpu/31.60/ubuntu> (suite C<resolute>, C<noble>,
C<jammy>) with C<linux-headers-$(uname -r)>, and on 24.04 and 22.04
C<linux-modules-extra-$(uname -r)> where apt has it -- the 7.0 kernels have
none (C<amdgpu.ko> is in C<linux-modules>). Never the
C<linux-headers-generic> metapackage, which pulls a new kernel. Without an
apt candidate for the headers or C<amdgpu-dkms> it dies after C<apt-get
update>, before any package is installed, with the repository and its key
in place. Installed headers count; the running kernel's headers that are
not installed are gone from the archive once it has moved on to a newer
kernel (a kernel update the host was not rebooted into) -- then the
message says to upgrade the kernel and reboot first.

=item * B<inbox>: the kernel's own C<amdgpu>. For any GPU but the Ryzen
APUs and the Radeon GPUs (below) this checks neither the release nor the
kernel series; L</release_data> only names the packages added when
missing: on 26.04
and 24.04, when neither C<linux-firmware-amd-graphics> nor
C<linux-firmware> is installed, the first of them apt has a candidate for;
on 22.04 C<linux-firmware> when it is not installed; on 24.04 and 22.04
C<linux-modules-extra-$(uname -r)> when the kernel has no C<amdgpu.ko>. It
dies, before installing anything, if apt has no candidate. On another
release no firmware package is checked or installed, and a kernel without
C<amdgpu.ko> dies before any change, as on 26.04. The Ryzen APUs (rows with
C<driver =E<gt> 'inbox'>) only on 26.04 (GA kernel 7.0) and on 24.04 with
the HWE kernel 7.0, both C<-generic>; no kernel is installed. On any other
release or kernel (on the 24.04 GA kernel 6.8 the message names the kernel
to boot) L<Rex::GPU::AMD/install_driver> dies before any change for them,
unless their driver already works, which it answers with C<present>
(C<method =E<gt> 'dkms'> dies then too).

=item * B<Radeon GPUs> (gfx target rows with C<matrix =E<gt> 'radeon'>,
L<Rex::GPU::AMD::Hardware/targets>), with
either driver, only where AMD's matrix lists them, which is not where it
lists the Instinct GPUs: on 26.04 with the GA kernel 7.0, on 24.04 with the
HWE kernel 7.0 and on 22.04 with the HWE kernel 6.8, all C<-generic>
(L</radeon_unsupported>). On the 24.04 GA kernel 6.8, the 22.04 GA kernel
5.15 or another release L<Rex::GPU::AMD/install_driver> dies before any
change for them, naming the kernel; no kernel is installed. A working
driver is answered with C<present>, as everywhere. That the Radeon list
binds C<inbox> too, and not only the C<amdgpu-dkms> the matrix names, is
this distribution's reading: the matrix lists the operating
systems per GPU table.

=back

=head2 release_data

The row of this Ubuntu release (C<VERSION_ID>), C<undef> for another one:

  release  amdgpu-dkms kernels  Radeon GPUs  inbox-only GPUs (APUs)  ROCm repo
  26.04    7.0                  7.0          7.0                     ubuntu2604
  24.04    6.8, 7.0             7.0 (HWE)    7.0 (HWE)               ubuntu2404
  22.04    5.15, 6.8            6.8 (HWE)    --                      ubuntu2204

Kernels are the C<MAJOR.MINOR> of a C<-generic> C<uname -r>
(C<7.0.0-42-generic>), from the ROCm 10.1 compatibility matrix. The
C<amdgpu-dkms> kernels are the Instinct table's; the Radeon GPUs
(C<matrix =E<gt> 'radeon'>) are bound to their own, for C<inbox> and
C<amdgpu-dkms> alike (L</radeon_unsupported>). The Radeon and inbox-only
columns bind the gfx targets of those GPUs for
L<Rex::GPU::AMD/install_rocm> too.

=head2 kernel_series

C<MAJOR.MINOR> of the running kernel if it is a C<-generic> one, else
C<undef> (no other flavour is in AMD's matrix).

=head2 radeon_unsupported

C<undef> when the running kernel is one L</release_data> lists for the
Radeon GPUs on this release (C<-generic>), else the reason, naming the
kernel series; on a release without a row the reason of
L<Rex::GPU::AMD::Setup/radeon_unsupported>. Host-read-only.

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
