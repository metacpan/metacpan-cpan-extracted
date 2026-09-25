# ABSTRACT: NVIDIA driver setup for Ubuntu (experimental)

package Rex::GPU::NVIDIA::Setup::Ubuntu;
our $VERSION = '0.002';
use Moo;
use Rex::Logger ();
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup::Apt';


sub kernel_packages {
  my ( $self ) = @_;
  return ( $self->SUPER::kernel_packages, 'linux-headers-generic' );
}


# 580 is published for jammy and noble (Launchpad, source
# nvidia-graphics-drivers-580-server, checked 2026-09-23: 580.178.04 on both,
# next to 590 and 595). The apt-cache search runs in resolve_source, after
# `apt-get update` -- before it, a fresh image's index is stale or empty
# (karr #35).
#
# Fabric Manager (karr #23): Ubuntu's archive builds nvidia-fabricmanager-NNN
# (source fabric-manager-NNN) for each -server branch, one package for the
# proprietary and the -open driver; it Depends on the virtual
# nvidia-kernel-common-NNN-server-<exact upstream version>, and on noble and
# jammy it carries exactly the version string of nvidia-driver-NNN-server
# (packages.ubuntu.com, 580.178.04-0ubuntu0.24.04.1 / 22.04.1, checked
# 2026-09-24).
sub sources {
  my ( $self ) = @_;
  my %fm = ( fabric_manager => 'nvidia-fabricmanager-%s' );
  return (
    {
      name            => 'ubuntu-server',
      kernel_module   => 'proprietary',
      branch_at_least => 580,
      search          => '^nvidia-driver-[0-9].*-server$',
      %fm,
      fabric_manager_match => 'nvidia-driver-%s-server'
    },
    {
      name            => 'ubuntu-server-open',
      kernel_module   => 'open',
      branch_at_least => 580,
      search          => '^nvidia-driver-[0-9].*-server-open$',
      %fm,
      fabric_manager_match => 'nvidia-driver-%s-server-open'
    },
    {
      name            => 'ubuntu-server-580',
      kernel_module   => 'proprietary',
      branch          => 580,
      packages        => [ 'nvidia-driver-580-server' ],
      verify          => [ 'nvidia-driver-580-server' ],
      check_candidate => 'nvidia-driver-580-server',
      %fm,
      fabric_manager_match => 'nvidia-driver-580-server'
    }
  );
}


sub nvlink_fabric_packages {
  my ( $self ) = @_;
  # ib_umad.ko is in linux-modules-extra-<kver> (research 2026-09-24,
  # checked for 6.8.0-142-generic); the running kernel's own package.
  return ( $self->SUPER::nvlink_fabric_packages, 'linux-modules-extra-'.$self->kernel );
}

# nvlsm verified in repos/ubuntu2204 and repos/ubuntu2404 (x86_64), research
# of 2026-09-24; not in Ubuntu's archive, not in DOCA.
my %NVLSM_REPO = ( '22.04' => 'ubuntu2204', '24.04' => 'ubuntu2404' );

sub _nvlsm_repo {
  my ( $self ) = @_;
  my ($release) = ( $self->release // '' ) =~ /^(\d+\.\d+)/;
  my $distro = defined $release ? $NVLSM_REPO{$release} : undef;
  return unless defined $distro && ( $self->arch // '' ) eq 'amd64';
  return {
    distro      => $distro,
    arch        => 'x86_64',
    url         => "https://developer.download.nvidia.com/compute/cuda/repos/$distro/x86_64/",
    keyring_url => "https://developer.download.nvidia.com/compute/cuda/repos/$distro/x86_64/cuda-keyring_1.1-1_all.deb"
  };
}

sub nvlink_fabric_unavailable {
  my ( $self ) = @_;
  return if $self->_nvlsm_repo;
  return "nvlsm is only in NVIDIA's CUDA repository, which Rex::GPU uses for it on Ubuntu "
    ."22.04 and 24.04 (amd64) only, not on release '".( $self->release // '' )."' ("
    .( $self->arch // '' ).')';
}

sub nvlsm_pin_file    { '/etc/apt/preferences.d/rex-gpu-nvlsm.pref' }
sub nvlsm_source_file { '/etc/apt/sources.list.d/rex-gpu-nvlsm.list' }

sub prepare_nvlink_fabric_source {
  my ( $self, $plan ) = @_;
  my $repo = $self->_nvlsm_repo
    or die 'No NVIDIA CUDA repository for nvlsm on this Ubuntu host; the driver and '
      ."Fabric Manager are installed, nvlsm is not\n";
  $self->run_cmd("dpkg -l cuda-keyring 2>/dev/null | grep -q '^ii'", auto_die => 0);
  if ($? == 0) {
    Rex::Logger::info('  cuda-keyring is installed: NVIDIA\'s CUDA repository is already '
      .'configured (with its own apt pin), nothing is added');
    $self->refresh_package_index;
    return;
  }
  Rex::Logger::info("  Adding NVIDIA's CUDA repository ($repo->{distro}/$repo->{arch}) for nvlsm "
    .'only, every other package of it pinned out');
  my $keyring = '/usr/share/keyrings/cuda-archive-keyring.gpg';
  $self->run_cmd('DEBIAN_FRONTEND=noninteractive '.$self->apt_get.' install -y --no-upgrade curl',
    auto_die => 0);
  $self->verify_packages({ verify => [ 'curl' ] });
  $self->run_cmd(q{t=$(mktemp -d) && curl -fsSL -o "$t/cuda-keyring.deb" }.$repo->{keyring_url}
    .q{ && dpkg-deb --fsys-tarfile "$t/cuda-keyring.deb" | tar -xO ./usr/share/keyrings/cuda-archive-keyring.gpg > "$t/key.gpg"}
    .q{ && test -s "$t/key.gpg" && install -m 0644 "$t/key.gpg" }.$keyring
    .q{; rc=$?; rm -rf "$t"; exit $rc},
    auto_die => 0);
  die "Could not fetch the signing key of NVIDIA's CUDA repository ($repo->{keyring_url}) "
    ."into $keyring; the driver and Fabric Manager are installed, nvlsm is not\n" if $? != 0;
  $self->file_cmd($self->nvlsm_pin_file, content => $self->_nvlsm_pin, mode => 644);
  $self->file_cmd($self->nvlsm_source_file,
    content => 'deb [signed-by='.$keyring.'] '.$repo->{url}." /\n", mode => 644);
  $self->refresh_package_index;
  return;
}

# apt_preferences(5): the first specific-form record (Package: nvlsm) decides
# nvlsm's priority; every other package of that origin gets the general
# record's -1, "prevents the version from being installed". cuda-keyring's
# own pin (Package: * / release l=NVIDIA CUDA / 600) is NOT installed: a
# general record, it would win the maximum over -1.
sub _nvlsm_pin {
  return join("\n",
    'Explanation: Rex::GPU (HGX B200/B300): NVIDIA\'s CUDA repository is here for nvlsm only.',
    'Explanation: Nothing else is installed or upgraded from it; the NVIDIA driver stays Ubuntu\'s.',
    'Package: *',
    'Pin: origin developer.download.nvidia.com',
    'Pin-Priority: -1',
    '',
    'Package: nvlsm',
    'Pin: origin developer.download.nvidia.com',
    'Pin-Priority: 500',
    '');
}


sub resolve_source {
  my ( $self, $source ) = @_;
  if (defined $source->{search}) {
    my $latest = $self->run_cmd("apt-cache search '$source->{search}' 2>/dev/null | sort -t- -k3 -n | tail -1 | awk '{print \$1}'",
      auto_die => 0);
    chomp $latest if $latest;
    # Filter out *-open variants from auto-detect (use regular server driver)
    $latest = undef if $latest && $source->{kernel_module} ne 'open' && $latest =~ /-open$/;
    return { %$source, unavailable => "apt-cache search '".$source->{search}."' finds no "
      .'package after apt-get update (did the update fail, or is the restricted '
      .'component missing from the apt sources?)' }
      unless $latest;
    my ($branch) = $latest =~ /^nvidia-driver-(\d+)-server/;
    return { %$source, unavailable => 'no driver branch in the package name '.$latest }
      unless defined $branch;
    my %resolved = ( %$source, packages => [ $latest ], verify => [ $latest ], branch => $branch );
    delete $resolved{branch_at_least};
    return \%resolved;
  }
  if (defined $source->{check_candidate}) {
    my $pinned = $source->{check_candidate};
    my $policy = $self->run_cmd("LC_ALL=C apt-cache policy $pinned 2>/dev/null", auto_die => 0);
    return { %$source, unavailable => $pinned.' has no installation candidate after '
      .'apt-get update, and no other package is substituted' }
      unless $self->_apt_candidate_present($policy);
  }
  return $source;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Setup::Ubuntu - NVIDIA driver setup for Ubuntu (experimental)

=head1 VERSION

version 0.002

=head1 DESCRIPTION

B<Experimental>, like L<Rex::GPU::NVIDIA::Setup>. The NVIDIA driver install
for Ubuntu: the C<-server> driver packages from Ubuntu's own archive on the
apt layer L<Rex::GPU::NVIDIA::Setup::Apt>. On an HGX B200/B300 also
Ubuntu's C<nvidia-fabricmanager-NNN>, and C<nvlsm> from NVIDIA's CUDA
repository, pinned so that nothing else comes from it
(L</prepare_nvlink_fabric_source>).

=head2 kernel_packages

The apt layer's running-kernel headers, plus C<linux-headers-generic>.

=head2 sources

Ubuntu's own C<-server> driver packages, in this order; each installs one
package, which is also the one verified:

=over

=item * C<ubuntu-server> -- the newest C<nvidia-driver-NNN-server>
(proprietary kernel module) that C<apt-cache search> finds (C<-open>
filtered out).

=item * C<ubuntu-server-open> -- the newest
C<nvidia-driver-NNN-server-open> (open kernel module).

=item * C<ubuntu-server-580> -- C<nvidia-driver-580-server>, proprietary,
branch 580 exactly. Its installation candidate is checked after
C<apt-get update> (L</resolve_source>); no other branch is substituted.

=back

L<Rex::GPU::NVIDIA::Setup/plan> chooses among them without a package index:
the first two count as "newest branch, at least 580" -- 580 is in the
archive of every supported release -- so they fit a GPU that needs 570 or
580 or newer but never one that stops at 580. Which package that is, and
its exact branch, is looked up only after C<apt-get update>
(L</resolve_source>) and checked again; nothing found, or a branch the GPU
cannot use, dies before any driver package is installed. There is no
hard-coded fallback package, and no other source is tried then.

So a GPU without constraints (Turing to Hopper, no GPU) gets
C<ubuntu-server>, Blackwell C<ubuntu-server-open>, Maxwell/Pascal/Volta
C<ubuntu-server-580>.

Each names C<nvidia-fabricmanager-NNN> as its Fabric Manager (for a host
with NVSwitches, see L<Rex::GPU::NVIDIA::Setup/nvswitches>): NNN is the
branch found after C<apt-get update>, and it is installed at the upstream
version of the installed C<nvidia-driver-NNN-server(-open)>.

Never C<nvidia-smi>: on 24.04 it is a virtual package with no installation
candidate, and the driver metapackage pulls it in anyway.

=head2 nvlink_fabric_packages

The apt layer's (C<nvlsm>, C<infiniband-diags>, C<libibumad3>) plus
C<linux-modules-extra-$kernel> of the running kernel, which holds the
C<ib_umad> module on Ubuntu -- the running kernel's package only, never a
metapackage that pulls a new kernel.

=head2 nvlink_fabric_unavailable

A reason unless the release is 22.04 or 24.04 on amd64: NVIDIA's CUDA
repositories C<ubuntu2204>/C<ubuntu2404> for C<x86_64> are where C<nvlsm>
was verified; Ubuntu's archive has none.

=head2 prepare_nvlink_fabric_source

Ubuntu's archive has no C<nvlsm>, so on an HGX B200/B300 -- and only there
-- NVIDIA's CUDA repository is added, B<after> the driver and Fabric Manager
are installed and verified, so it cannot influence which driver package
L</resolve_source> finds:

=over

=item * the repository's signing key is taken from NVIDIA's
C<cuda-keyring_1.1-1_all.deb> (downloaded with C<curl -f>, unpacked with
C<dpkg-deb>) into C</usr/share/keyrings/cuda-archive-keyring.gpg>; the
package itself is B<not> installed, because it also installs
C</etc/apt/preferences.d/cuda-repository-pin-600>, which raises every
package of that repository to priority 600 -- above Ubuntu's own driver;

=item * L</nvlsm_pin_file> pins every package of
C<developer.download.nvidia.com> to priority -1 (never installed) except
C<nvlsm> (500) -- the driver, Fabric Manager and every library stay
Ubuntu's, now and on later upgrades; it is written before the source;

=item * L</nvlsm_source_file> gets the repository line, then C<apt-get
update>.

=back

A host that has C<cuda-keyring> installed already has the repository (with
NVIDIA's own pin): nothing is added there, only C<apt-get update>. Dies,
before anything is added, when the key cannot be fetched; the driver and
Fabric Manager stay installed.

=head2 nvlsm_pin_file

C</etc/apt/preferences.d/rex-gpu-nvlsm.pref>.

=head2 nvlsm_source_file

C</etc/apt/sources.list.d/rex-gpu-nvlsm.list>.

=head2 resolve_source

Runs after the apt layer's C<apt-get update>
(L<Rex::GPU::NVIDIA::Setup/resolve_plan>), read-only:

=over

=item * a source with a C<search> pattern: C<apt-cache search> for the
newest matching package; returns the source with that one package (installed
and verified) and the exact branch from its name. Nothing found, or a name
without a branch, makes it C<unavailable> -- there is no fallback package:
if the refreshed index does not list one, C<apt-get install> could not
install it either.

=item * a source with C<check_candidate>: C<apt-cache policy> must show an
installation candidate for that package, else the source is
C<unavailable>. No other package is substituted.

=back

Any other source is returned unchanged. A subclass that picks the package
another way overrides this method; the requirement check after it stays.

=head1 SEE ALSO

L<Rex::GPU::NVIDIA::Setup>, L<Rex::GPU::NVIDIA/install_driver>

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
