# ABSTRACT: AMD driver setup for RHEL, Rocky Linux and AlmaLinux 8, 9 and 10 (experimental)

package Rex::GPU::AMD::Setup::RHEL;
our $VERSION = '0.006';
use Moo;
use Rex::Logger ();
use namespace::autoclean;

extends 'Rex::GPU::AMD::Setup';

# Sources, checked 2026-10-30:
#   ROCm 10.1 compatibility matrix (Instinct, amdgpu-dkms): RHEL 10.2
#     6.12.0-211, 10.0 6.12.0-55, 9.8 5.14.0-687, 9.6 5.14.0-570, 9.4
#     5.14.0-427, 8.10 4.18.0-553; Rocky 9 5.14.0-570. Radeon: RHEL 10.2, 9.8.
#     No Ryzen APU support on RHEL. The Radeon list names the releases only;
#     %RADEON binds each to the kernel build the Instinct list gives that
#     release (10.2 6.12.0-211, 9.8 5.14.0-687) -- this distribution's
#     reading (k82), as strict as the amdgpu-dkms check, for either driver.
#     Rocky and AlmaLinux with the same VERSION_ID count as RHEL, as they do
#     for amdgpu-dkms.
#   amdgpu 31.60 install guide, RHEL: /etc/yum.repos.d/amdgpu.repo, baseurl
#     https://repo.radeon.com/amdgpu/31.60/el/MAJOR/main/x86_64/, priority=50,
#     gpgcheck=1; kernel-headers-$K kernel-devel-$K kernel-devel-matched-$K
#     (8.10: without -matched). The repository ships its own dkms.
#   Firmware for the inbox amdgpu: amd-gpu-firmware on EL10 (split off
#     linux-firmware), linux-firmware on EL9 and EL8.
my %MAJOR = (
  10 => { kernel => qr/\A6\.12\.0-(?:211|55)\./, kernel_text => '6.12.0-211 or 6.12.0-55',
          matched => 1, firmware => [qw( amd-gpu-firmware )] },
  9  => { kernel => qr/\A5\.14\.0-(?:687|570|427)\./, kernel_text => '5.14.0-687, -570 or -427',
          matched => 1, firmware => [qw( linux-firmware )] },
  8  => { kernel => qr/\A4\.18\.0-553\./, kernel_text => '4.18.0-553',
          matched => 0, firmware => [qw( linux-firmware )] },
);
my %RADEON = (
  '10.2' => { kernel => qr/\A6\.12\.0-211\./, kernel_text => '6.12.0-211' },
  '9.8'  => { kernel => qr/\A5\.14\.0-687\./, kernel_text => '5.14.0-687' },
);


sub major {
  my ( $self ) = @_;
  return $self->os_version =~ /\A(\d+)/ ? $1 : undef;
}

sub release_data {
  my ( $self ) = @_;
  my $major = $self->major // return;
  return $MAJOR{$major};
}

sub amdgpu_key_path { '/etc/pki/rpm-gpg/RPM-GPG-KEY-rocm' }

sub dkms_repo {
  my ( $self ) = @_;
  my $key = $self->amdgpu_key;
  return {
    file    => '/etc/yum.repos.d/amdgpu.repo',
    content => join("\n",
      '[amdgpu]',
      'name=amdgpu',
      'baseurl=https://repo.radeon.com/amdgpu/'.$self->amdgpu_release.'/el/'
        .( $self->major // 'unknown' ).'/main/x86_64/',
      'enabled=1',
      'priority=50',
      'gpgcheck=1',
      'gpgkey=file://'.$key->{path}, ''),
    key     => $key,
  };
}

sub dkms_unsupported {
  my ( $self ) = @_;
  my $row = $self->release_data
    or return 'amdgpu-dkms '.$self->amdgpu_release.' supports RHEL 8, 9 and 10, not '.$self->os_label;
  return if $self->kernel =~ $row->{kernel};
  return 'amdgpu-dkms '.$self->amdgpu_release.' supports '.$self->os_label.' with kernel '
    .$row->{kernel_text}.'; this host runs '.$self->kernel;
}

sub radeon_unsupported {
  my ( $self ) = @_;
  my $row = $RADEON{ $self->os_version } or return $self->SUPER::radeon_unsupported;
  return if $self->kernel =~ $row->{kernel};
  return 'AMD supports Radeon GPUs on '.$self->os_label.' with kernel '.$row->{kernel_text}
    .' only; this host runs '.$self->kernel;
}

sub kernel_header_packages {
  my ( $self ) = @_;
  my $kernel = $self->kernel;
  my $row = $self->release_data;
  return ( "kernel-headers-$kernel", "kernel-devel-$kernel",
    ( $row && $row->{matched} ? "kernel-devel-matched-$kernel" : () ) );
}

sub firmware_packages {
  my ( $self ) = @_;
  my $row = $self->release_data or return;
  return @{ $row->{firmware} };
}


# repoquery prints one NEVRA per match (name-epoch:version-release.arch, dnf
# 4 and 5 alike) and exits 0 also when nothing matches; it exits non-zero
# only when it could not run, e.g. metadata that cannot be downloaded --
# which must not read as "no candidate". Other output (warnings, with 2>&1)
# has spaces and is no NEVRA.
sub has_candidate {
  my ( $self, $package ) = @_;
  return 1 if $self->package_installed($package);
  my $out = $self->run_cmd("dnf -q repoquery --available $package 2>&1") // '';
  if ($? != 0) {
    my ( $why ) = reverse grep { /\S/ } split /\r?\n/, $out;
    $why = defined $why ? $why =~ s/\A\s+|\s+\z//gr : 'no output';
    die "install_driver: looking up $package with dnf failed ($why). No driver package was "
      ."installed\n";
  }
  return ( grep { /\A\s*\S+-\d+:\S+\s*\z/ } split /\r?\n/, $out ) ? 1 : 0;
}

sub package_installed {
  my ( $self, $package ) = @_;
  $self->run_cmd("rpm -q $package 2>&1");
  return $? == 0 ? 1 : 0;
}

sub install_helpers {
  my ( $self ) = @_;
  my @missing;
  for my $helper ([ curl => 'curl' ], [ gpg => 'gnupg2' ]) {
    $self->run_cmd("command -v $helper->[0] >/dev/null 2>&1");
    push @missing, $helper->[1] if $? != 0;
  }
  return unless @missing;
  $self->run_cmd('dnf install -y '.join(' ', @missing));
  $self->verify_packages({ packages => \@missing });
  return;
}

sub install_packages {
  my ( $self, $plan ) = @_;
  Rex::Logger::info('  Installing: '.join(', ', @{ $plan->{packages} }));
  $self->run_cmd('dnf install -y '.join(' ', @{ $plan->{packages} }));
  return;
}

sub verify_packages {
  my ( $self, $plan ) = @_;
  for my $package (@{ $plan->{packages} }) {
    next if $self->package_installed($package);
    my $hold = $self->hold_note($plan);
    die "$package not installed after dnf install -- check the dnf output"
      .( length $hold ? "; $hold" : '' )."\n";
  }
  return;
}

# k109: the counterpart of the apt hold. A lock (dnf 4 versionlock plugin,
# dnf 5 built in) leaves an installed package at its locked version and
# keeps every other version out, so `dnf install` of a version it excludes
# fails as a whole (strict) -- or does nothing for a package installed at
# the locked version. Asked only on a failure path; a dnf without the
# plugin, or a list that cannot be read, is no lock (k109: nothing dies,
# nothing is installed for it).
sub package_held {
  my ( $self, $package ) = @_;
  return $self->_locked($self->_package_name($package), $self->_versionlock_entries) ? 1 : 0;
}

sub blocking_holds {
  my ( $self, $plan ) = @_;
  my @entries = $self->_versionlock_entries or return;
  my %asked = map { $_ => 1 } @{ $plan->{packages} || [] };
  my @held;
  for my $package ($self->_hold_packages($plan)) {
    my $name = $self->_package_name($package);
    next unless $self->_locked($name, @entries);
    # a spec with the kernel's version is one build, a dependency is required
    # without a version: installed, the lock kept nothing out
    push @held, $name
      if ( $asked{$package} && $package eq $name ) || !$self->package_installed($package);
  }
  return @held;
}

sub hold_advice {
  my ( $self, @held ) = @_;
  return $self->_and_list(@held).( @held > 1 ? ' are' : ' is' ).' version-locked (dnf versionlock), '
    .'and dnf install leaves a locked package at its locked version (where the install needs another '
    .'one, it fails). Run dnf versionlock delete '.join(' ', @held).' and install_driver again';
}

# dnf 4 (python3-dnf-plugin-versionlock) prints the lock list's entries as
# they were added, NAME-EPOCH:VERSION-RELEASE.*, "!" in front for an
# exclude; dnf 5 prints "Package name: NAME" per entry, then its
# conditions ("evr = ..."). Lines with a space or a "#" (conditions,
# comments, dnf's own messages) are no entry. Exit status not 0 (no plugin,
# an unreadable list): no entries.
sub _versionlock_entries {
  my ( $self ) = @_;
  my $out = $self->run_cmd('dnf -q versionlock list 2>/dev/null') // '';
  return if $? != 0;
  my @entries;
  for my $line (split /\r?\n/, $out) {
    $line =~ s/\A\s+|\s+\z//g;
    if ($line =~ /\APackage name:\s*(\S+)\z/) { push @entries, $1 }
    elsif (length $line && $line !~ /[\s#]/) { push @entries, $line =~ s/\A!//r }
  }
  return @entries;
}

# An entry is for NAME when it is NAME, or NAME, a dash and an epoch or a
# version (a digit, or a glob): kernel-devel-0:5.14.0-570.12.1.el9_6.* is
# kernel-devel's, kernel-devel-matched-0:... is not.
sub _locked {
  my ( $self, $name, @entries ) = @_;
  return scalar grep { $_ eq $name || /\A\Q$name\E-(?:\d+:)?[\d*]/ } @entries;
}

# The package name of a spec: kernel-devel-$(uname -r) is kernel-devel.
sub _package_name {
  my ( $self, $package ) = @_;
  my $kernel = $self->kernel;
  return $package =~ s/-\Q$kernel\E\z//r;
}

sub place_key {
  my ( $self, $dir, $path ) = @_;
  $self->run_cmd("chmod 0644 $dir/key.asc && mv -f $dir/key.asc $path && rpm --import $path");
  return $? == 0 ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::AMD::Setup::RHEL - AMD driver setup for RHEL, Rocky Linux and AlmaLinux 8, 9 and 10 (experimental)

=head1 VERSION

version 0.006

=head1 DESCRIPTION

B<Experimental.> The AMD driver on RHEL, Rocky Linux and AlmaLinux:

=over

=item * B<amdgpu-dkms> on 8, 9 and 10, per L</release_data>: from
C<repo.radeon.com/amdgpu/31.60/el/MAJOR> with the running kernel's
C<kernel-headers>, C<kernel-devel> and (9, 10) C<kernel-devel-matched>, on
the kernel builds of AMD's matrix only. The repository's signing key is
checked against its pinned fingerprint and imported into rpm. After the
repository is written each of these packages must be installed or offered
by an enabled repository (L</has_candidate>), else it dies before any
package is installed -- for a header package with the advice to upgrade
the kernel and reboot (Rocky and Alma move a superseded minor release's
builds to their vault); the re-run checks the new kernel against AMD's
matrix again.

=item * B<inbox>, which checks neither the release nor the kernel but for
the Radeon GPUs (below); L</release_data> only names the firmware package:
the kernel's own
C<amdgpu>, plus the firmware package (C<amd-gpu-firmware> on 10,
C<linux-firmware> on 9 and 8) when it is not installed (it dies, before
installing anything, if no enabled repository offers it) -- on another
major release none is checked or installed. No package is known that adds a
missing C<amdgpu.ko>: it dies then, before any change. The GPUs AMD
supports only with the inbox driver (the Ryzen APUs) are not supported on
RHEL: L<Rex::GPU::AMD/install_driver> dies before any change for them,
unless their driver already works, which it answers with C<present>
(C<method =E<gt> 'dkms'> dies then too).

=item * B<Radeon GPUs> (gfx target rows with C<matrix =E<gt> 'radeon'>,
L<Rex::GPU::AMD::Hardware/targets>), with either driver, only on the two
releases AMD's matrix lists them for, each with its kernel build: 10.2 with
C<6.12.0-211>, 9.8 with C<5.14.0-687> (L</radeon_unsupported>; Rocky Linux
and AlmaLinux of the same C<VERSION_ID> count as RHEL, as for
C<amdgpu-dkms>). On 10.0, 9.6, 9.4, 8.10, another release or kernel
L<Rex::GPU::AMD/install_driver> dies before any change for them; a working
driver is answered with C<present>, as everywhere. The matrix's Radeon
list names the releases only; the kernel build and that it binds C<inbox>
too are this distribution's reading.

=back

L<Rex::GPU::AMD/install_rocm> is not supported here (apt only).

=head2 major

The major release, from C<VERSION_ID> (C<9.6> is C<9>), C<undef> without.

=head2 release_data

The row of this major release (C<10>, C<9>, C<8>), C<undef> for another
one: the kernels AMD supports C<amdgpu-dkms> on (the matrix's RHEL kernel
builds, C<6.12.0-211>/C<-55>, C<5.14.0-687>/C<-570>/C<-427>,
C<4.18.0-553>), whether C<kernel-devel-matched> exists, the firmware
package.

=head2 radeon_unsupported

C<undef> on the two releases AMD's matrix lists the Radeon GPUs for --
C<VERSION_ID> C<10.2> with kernel C<6.12.0-211.*> and C<9.8> with
C<5.14.0-687.*>, RHEL, Rocky Linux or AlmaLinux --, else the reason
(another kernel: naming the one of the release; another release: the one
of L<Rex::GPU::AMD::Setup/radeon_unsupported>). Host-read-only.

=head2 has_candidate

True when the package is installed (L</package_installed>), else when
C<dnf -q repoquery --available PKG> lists it from an enabled repository --
the same answer C<apt-cache policy> gives on apt, where an installed
package is its own candidate. C<refresh_index> does nothing here: dnf
fetches the metadata it lacks (the just written C<amdgpu.repo>) or that has
expired itself, as C<dnf install> would; C<repoquery> applies the excludes
of C<dnf.conf> as C<dnf install> does. A package spec with version
(C<kernel-devel-$(uname -r)>) is matched as C<rpm -q> and C<dnf install>
match it. Dies, with dnf's last line, when C<repoquery> fails (a repository
whose metadata cannot be downloaded): no package was installed by then.
Read-only. Written for the dnf 4 of RHEL 8, 9 and 10; dnf 5's
C<repoquery> has the same options and also exits C<0> on no match.

=head2 package_installed

C<rpm -q PKG>. Read-only.

=head2 install_helpers

C<curl> and C<gpg>, only if C<command -v> does not find them: C<dnf
install -y curl gnupg2>, verified.

=head2 install_packages

C<dnf install -y> of the plan's packages, directly: never
L<Rex::Commands::Pkg>.

=head2 package_held

True when C<dnf -q versionlock list> has an entry for the package's name
(a kernel package spec C<NAME-KERNEL> of the running kernel counts as
C<NAME>): dnf 4's C<NAME-EPOCH:VERSION-RELEASE.*>, also as an exclude
(C<!...>) or as a bare C<NAME>, or dnf 5's C<Package name: NAME>. Whatever
version the entry names. Without the versionlock plugin (dnf 4:
C<python3-dnf-plugin-versionlock>, not installed by default), or when the
command fails for another reason (exit status not C<0>), nothing is held:
it never dies and installs nothing. Read-only.

=head2 blocking_holds

  my @held = $setup->blocking_holds($plan);

The names among the plan's C<packages> and
L<Rex::GPU::AMD::Setup/dkms_dependencies> that a lock is on (as
L</package_held> counts it) and that it can have kept out of the install:
C<amdgpu-dkms> as the plan asks for it (no version: the lock may keep it
below the newest), installed or not; every other one -- the running
kernel's C<kernel-headers>, C<kernel-devel>, C<kernel-devel-matched>, a
dependency required without a version -- only while C<rpm -q> does not
find it. One C<dnf -q versionlock list> (none of it when that lists no
lock or fails), then C<rpm -q> only for such a locked package. Read-only.

=head2 hold_advice

C<... is version-locked (dnf versionlock), and dnf install leaves a locked
package at its locked version (where the install needs another one, it
fails). Run dnf versionlock delete ... and install_driver again>.

=head2 verify_packages

Each of the plan's packages must be installed for C<rpm -q>; dies
otherwise. For C<amdgpu-dkms> that is not enough (a failed C<%post> build
leaves it installed): L<Rex::GPU::AMD::Setup/post_install> checks C<dkms
status>. For a C<dkms> plan the message names the locks
L</blocking_holds> finds (L<Rex::GPU::AMD::Setup/hold_note>) as the cause,
with C<dnf versionlock delete> of them as the way out; asked only once a
package is missing.

=head2 place_key

The checked armored key to C<path> (mode 0644), then C<rpm --import> of
it; the repository's C<gpgkey> points at that file.

=head1 SEE ALSO

L<Rex::GPU::AMD::Setup>

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
