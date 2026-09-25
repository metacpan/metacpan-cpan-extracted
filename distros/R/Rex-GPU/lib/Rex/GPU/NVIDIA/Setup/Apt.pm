# ABSTRACT: apt/dpkg packaging layer of the NVIDIA driver setups (experimental)

package Rex::GPU::NVIDIA::Setup::Apt;
our $VERSION = '0.002';
use Moo;
use Rex::Logger ();
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup';


has apt_lock_timeout => ( is => 'ro', default => 120 );

sub _build_arch {
  my ( $self ) = @_;
  my $arch = $self->run_cmd('dpkg --print-architecture', auto_die => 0);
  chomp $arch;
  return $arch;
}


sub apt_get {
  my ( $self ) = @_;
  return 'apt-get -o DPkg::Lock::Timeout='.$self->apt_lock_timeout;
}


sub kernel_packages {
  my ( $self ) = @_;
  $self->arch;
  return 'linux-headers-'.$self->kernel;
}


sub prepare_host {
  my ( $self, $plan ) = @_;
  $self->run_cmd('systemctl stop unattended-upgrades apt-daily.service apt-daily-upgrade.service 2>/dev/null || true',
    auto_die => 0);
}


sub prepare_source {
  my ( $self, $plan ) = @_;
  $self->refresh_package_index;
}


sub refresh_package_index {
  my ( $self ) = @_;
  $self->run_cmd($self->apt_get.' update -q', auto_die => 0);
}


sub installed_fabric_managers {
  my ( $self ) = @_;
  my $out = $self->run_cmd(q{dpkg-query -W -f='${Package} ${db:Status-Abbrev} ${Version}\n' 'nvidia-fabric*manager*' 2>/dev/null},
    auto_die => 0);
  my @present;
  for my $line (split /\n/, $out // '') {
    my ( $name, $status, $version ) = split ' ', $line;
    next unless $self->_is_fabric_manager_name($name);
    next unless defined $status && $status =~ /\A[a-z]([a-zA-Z])/ && $1 ne 'n' && $1 ne 'c';
    push @present, [ $name, $self->_dpkg_upstream_version($version) ];
  }
  return @present;
}

sub fabric_manager_version_unavailable {
  my ( $self, $pkg, $version ) = @_;
  my $madison = $self->run_cmd("apt-cache madison $pkg 2>/dev/null", auto_die => 0);
  my $full = $self->_madison_version_for($madison, $version);
  return 'apt-cache madison '.$pkg.' lists no version '.$version unless defined $full;
  my $sim = $self->run_cmd('LC_ALL=C '.$self->apt_get.' -s install '.$pkg.'='.$full.' 2>&1',
    auto_die => 0);
  return 'apt-get -s install '.$pkg.'='.$full.' fails' if $? != 0;
  my @removed = map { /^Remv (\S+)/ ? $1 : () } split /\n/, $sim // '';
  return 'installing '.$pkg.'='.$full.' would remove '.join(', ', @removed) if @removed;
  return;
}


sub install_packages {
  my ( $self, $plan ) = @_;
  Rex::Logger::info('  Installing: '.join(', ', @{ $plan->{packages} }));
  my $pkg_str = join(' ', @{ $plan->{packages} });
  $self->run_cmd('DEBIAN_FRONTEND=noninteractive '.$self->apt_get.' install -y '.$pkg_str, auto_die => 0);
}


sub verify_packages {
  my ( $self, $plan ) = @_;
  for my $driver_pkg (@{ $plan->{verify} }) {
    my $check = $self->run_cmd("dpkg -l $driver_pkg 2>/dev/null | grep -q '^ii'", auto_die => 0);
    die "$driver_pkg not installed after apt-get install — check apt output\n"
      if $? != 0;
  }
}


sub fabric_manager_unavailable {
  my ( $self, $pkg ) = @_;
  my $policy = $self->run_cmd("LC_ALL=C apt-cache policy $pkg 2>/dev/null", auto_die => 0);
  return if $self->_apt_candidate_present($policy);
  return $pkg.' has no installation candidate after apt-get update';
}

sub installed_driver_version {
  my ( $self, $source ) = @_;
  my $pkg = $self->_with_branch($source->{fabric_manager_match}, $source);
  die "The driver source names no package to read the driver version from "
    ."(fabric_manager_match); the driver is installed, Fabric Manager is not\n"
    unless defined $pkg;
  return $self->_dpkg_upstream_version($self->_dpkg_version($pkg));
}

sub install_versioned_package {
  my ( $self, $pkg, $version ) = @_;
  my $madison = $self->run_cmd("apt-cache madison $pkg 2>/dev/null", auto_die => 0);
  my $full = $self->_madison_version_for($madison, $version);
  die "apt has no $pkg of driver version $version (apt-cache madison $pkg); Fabric "
    ."Manager must match the driver exactly, so none was installed. The driver is "
    ."installed, Fabric Manager is not\n" unless defined $full;
  $self->run_cmd('DEBIAN_FRONTEND=noninteractive '.$self->apt_get.' install -y '.$pkg.'='.$full,
    auto_die => 0);
}

sub verify_versioned_package {
  my ( $self, $pkg, $version ) = @_;
  $self->verify_packages({ verify => [ $pkg ] });
  my $installed = $self->_dpkg_upstream_version($self->_dpkg_version($pkg));
  die "$pkg is ".( $installed // 'unknown' )." after apt-get install, not the driver's "
    ."$version\n" unless defined $installed && $installed eq $version;
}

sub _dpkg_version {
  my ( $self, $pkg ) = @_;
  my $v = $self->run_cmd("dpkg-query -W -f='\${Version}' $pkg 2>/dev/null", auto_die => 0);
  return if $? != 0 || !defined $v;
  chomp $v;
  return $v;
}

# Pure: "1:580.95.05-0ubuntu1" -> "580.95.05". undef/empty -> undef.
sub _dpkg_upstream_version {
  my ( $self, $version ) = @_;
  return unless defined $version && length $version;
  ( my $up = $version ) =~ s/^\d+://;
  $up =~ s/-[^-]*$//;
  return $up;
}

# Pure: the first `apt-cache madison` version (madison lists newest first)
# whose upstream part is $upstream; undef if none.
sub _madison_version_for {
  my ( $self, $madison, $upstream ) = @_;
  for my $line (split /\n/, $madison // '') {
    my ( undef, $full ) = map { s/^\s+|\s+$//gr } split /\|/, $line;
    next unless defined $full && length $full;
    my $up = $self->_dpkg_upstream_version($full);
    return $full if defined $up && $up eq $upstream;
  }
  return;
}


# karr #56, research of 2026-09-24: the nvlsm .deb (CUDA repo, 2025.12.211)
# Depends on libibumad3; NVIDIA's gpu-driver-container installs
# `nvlsm infiniband-diags` unversioned; the Fabric Manager start script
# needs ibstat (infiniband-diags).
sub nvlink_fabric_packages { ( 'nvlsm', 'infiniband-diags', 'libibumad3' ) }


sub initramfs_command { 'update-initramfs -u 2>/dev/null' }

# Pure (karr #26): does `apt-cache policy PKG` output (LC_ALL=C) show an
# installation candidate? An unknown package prints nothing; a known one with
# nothing installable prints "Candidate: (none)".
sub _apt_candidate_present {
  my ( $self, $policy ) = @_;
  return 0 unless defined $policy;
  my ($candidate) = $policy =~ /^\s*Candidate:\s*(\S+)/m;
  return (defined $candidate && $candidate ne '(none)') ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Setup::Apt - apt/dpkg packaging layer of the NVIDIA driver setups (experimental)

=head1 VERSION

version 0.002

=head1 DESCRIPTION

B<Experimental>, like L<Rex::GPU::NVIDIA::Setup>. The apt/dpkg half shared by
L<Rex::GPU::NVIDIA::Setup::Debian> and L<Rex::GPU::NVIDIA::Setup::Ubuntu>:
the lock timeout on every C<apt-get>, stopping the apt timers, C<apt-get
update>, C<apt-get install> run directly and C<dpkg -l ... ^ii> as the only
evidence of an install.

=head2 apt_lock_timeout

Seconds C<apt-get> waits for the dpkg lock (C<-o DPkg::Lock::Timeout=>).
Default C<120>: on a fresh Hetzner boot cloud-init and unattended-upgrades
still hold it.

=head2 apt_get

  $self->apt_get           # "apt-get -o DPkg::Lock::Timeout=120"

The C<apt-get> invocation every command of this layer starts with.

=head2 kernel_packages

The running kernel's headers, C<linux-headers-$kernel>: enough for DKMS.
Never the C<linux-headers-$arch> metapackage, which pulls a new kernel whose
grub/initramfs post-install can exit non-zero. Reads the architecture first,
so C<dpkg --print-architecture> runs before any source is looked at, whether
or not the distro class needs it.

=head2 prepare_host

Stops C<unattended-upgrades>, C<apt-daily> and C<apt-daily-upgrade>: on a
fresh boot they hold C</var/lib/dpkg/lock-frontend> and C<apt-get> fails at
once even with a lock timeout.

=head2 prepare_source

C<apt-get update>, with C<auto_die =E<gt> 0>: it exits non-zero on snap/PPA
repository warnings that are no real failure. Whether it actually refreshed
the index shows in the next step, L<Rex::GPU::NVIDIA::Setup/resolve_plan>:
a driver source that reads the index finds nothing and dies there.

=head2 refresh_package_index

C<apt-get update -q> with the lock timeout and C<auto_die =E<gt> 0>, as in
L</prepare_source>. L<Rex::GPU::NVIDIA::Setup/retrofit_fabric_manager> runs
it before C<apt-cache madison>: on a host provisioned long ago the index may
list a Fabric Manager version the archive no longer serves (Ubuntu keeps
only the newest in C<-updates>), or miss one published since.

=head2 installed_fabric_managers

C<dpkg-query -W> of C<nvidia-fabric*manager*>: every Fabric Manager package
dpkg knows in a state other than not-installed or config-files-only
(half-installed counts: it is not touched either), with its upstream
version.

=head2 fabric_manager_version_unavailable

Host-read-only: C<apt-cache madison PKG> must list a version whose upstream
part is C<$version> (L</install_versioned_package> installs that one), and
a simulated C<apt-get -s install PKG=VERSION> must succeed without removing
any package -- Ubuntu's C<nvidia-fabricmanager-NNN> depends on the
C<-server> driver's kernel-common package, so next to another driver
flavour the real install could replace the running driver's packages.

=head2 install_packages

Logs the package list, then C<apt-get install -y> of
C<< $plan->{packages} >> through L<Rex::GPU::NVIDIA::Setup/run_cmd> with
C<auto_die =E<gt> 0> -- B<never> L<Rex::Commands::Pkg/pkg>. C<Rex::Pkg::Apt>
dies on any non-zero exit, and a DKMS module build, grub update or initramfs
regeneration routinely exits non-zero on success. Whether the install worked
is decided by L</verify_packages>, not by this exit code.

=head2 verify_packages

Dies unless every package in C<< $plan->{verify} >> is C<ii> in C<dpkg -l>.
A DKMS build that fails in postinst leaves the package half-configured (not
C<ii>), so a partial install dies here.

=head2 fabric_manager_unavailable

After C<apt-get update>, before the driver install: a reason unless
C<apt-cache policy> shows an installation candidate for the Fabric Manager
package.

=head2 installed_driver_version

The upstream part (no epoch, no Debian revision) of C<dpkg-query -W
-f='${Version}'> for the source's C<fabric_manager_match> package:
C<580.178.04-0ubuntu0.24.04.1> is C<580.178.04>.

=head2 install_versioned_package

Looks the package's versions up with C<apt-cache madison>, takes the first
(newest) whose upstream version is C<$version> -- the Debian revision may
differ from the driver's, e.g. NVIDIA's Ubuntu repository has driver
C<580.95.05-0ubuntu1> next to Fabric Manager C<580.95.05-1> -- and runs
C<apt-get install -y PKG=VERSION> with C<auto_die =E<gt> 0>. Dies before
installing anything when no version matches: a Fabric Manager of another
version aborts on the driver check.

=head2 verify_versioned_package

C<dpkg -l ... ^ii>, then the installed upstream version (C<dpkg-query>) must
be C<$version>.

=head2 nvlink_fabric_packages

C<nvlsm>, C<infiniband-diags>, C<libibumad3> (see
L<Rex::GPU::NVIDIA::Setup/nvlink_fabric_packages>): the Debian package names
C<nvlsm>'s own dependencies and NVIDIA's gpu-driver-container use.

=head2 initramfs_command

C<update-initramfs -u 2E<gt>/dev/null>.

=head1 SEE ALSO

L<Rex::GPU::NVIDIA::Setup>

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
