# ABSTRACT: NVIDIA driver setup for RHEL, Rocky, AlmaLinux and CentOS Stream (experimental)

package Rex::GPU::NVIDIA::Setup::RHEL;
our $VERSION = '0.002';
use Moo;
use Rex::Commands::Gather ();
use Rex::Logger ();
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup::Rpm';


sub major {
  my ( $self ) = @_;
  return $self->_major_version($self->release);
}


has os_release => ( is => 'lazy' );

sub _build_os_release {
  my ( $self ) = @_;
  my $out = $self->run_cmd('cat /etc/os-release 2>/dev/null', auto_die => 0);
  return {} if $? != 0;
  return $self->_parse_os_release($out);
}

# Pure: KEY=VALUE lines of os-release(5), the value unquoted.
sub _parse_os_release {
  my ( $self, $text ) = @_;
  my %kv;
  for my $line (split /\n/, $text // '') {
    next unless $line =~ /^([A-Z0-9_]+)=(.*?)\s*$/;
    my ( $key, $value ) = ( $1, $2 );
    $value =~ s/^(["'])(.*)\1$/$2/;
    $kv{$key} = $value;
  }
  return \%kv;
}

sub is_rhel {
  my ( $self ) = @_;
  return ($self->os_release->{ID} // '') eq 'rhel' ? 1 : 0;
}

sub rex_pkg_works {
  my ( $self ) = @_;
  return Rex::Commands::Gather::is_redhat($self->os) ? 1 : 0;
}


sub install_helpers {
  my ( $self, @packages ) = @_;
  return $self->pkg_cmd([ @packages ], ensure => 'present') if $self->rex_pkg_works;
  $self->run_cmd($self->package_manager.' install -y '.join(' ', @packages), auto_die => 0);
  $self->verify_packages({ verify => [ @packages ] });
}


sub kernel_packages {
  my ( $self ) = @_;
  return ( ($self->major >= 9 ? 'kernel-devel-matched' : 'kernel-devel-'.$self->kernel),
    'kernel-headers' );
}

# branch_at_least 580: every tree carries it. kmod-nvidia-open-dkms in
# repos/rhel{8,9}/{x86_64,sbsa} spans 515..615, in repos/rhel10 580..615
# (directory listings checked 2026-09-23).
#
# cuda-580-dkms (karr #26):
#   * RHEL 8/9: the CUDA repo's module stream nvidia-driver:580-dkms, whose
#     artifacts are kmod-nvidia-latest-dkms + nvidia-driver(-cuda) 3:580.*
#     (checked in repos/rhel{8,9}/x86_64 modules.yaml, 2026-09-23).
#   * RHEL 10: no module streams, so a dnf versionlock on '*nvidia*580*' per
#     NVIDIA's version-locking guide (docs.nvidia.com/datacenter/tesla/
#     driver-installation-guide/version-locking.html). repos/rhel10/x86_64
#     carries kmod-nvidia-latest-dkms, nvidia-driver and nvidia-driver-cuda at
#     580.x (checked 2026-09-23).
sub sources {
  my ( $self ) = @_;
  my $major = $self->major;
  my $open = $major >= 10
    ? { packages => [ 'kmod-nvidia-open-dkms', 'nvidia-driver', 'nvidia-driver-cuda' ] }
    : { packages => [ 'nvidia-open' ], module_stream => 'open-dkms', stream_optional => 1 };
  # Fabric Manager (karr #23): nvidia-fabricmanager, unversioned from 580 on,
  # epoch 0 (the driver packages carry epoch 3), no Requires on the driver;
  # an artifact of every nvidia-driver stream's /fm profile on rhel8/9
  # (repodata modules.yaml and primary.sqlite, checked 2026-09-24). Pinned
  # to the installed nvidia-driver's version.
  my %fm = ( fabric_manager => 'nvidia-fabricmanager', fabric_manager_match => 'nvidia-driver' );
  return (
    {
      name            => 'cuda-open-dkms',
      kernel_module   => 'open',
      branch_at_least => 580,
      verify          => [ 'nvidia-driver' ],
      %fm,
      %$open
    },
    {
      %fm,
      name          => 'cuda-580-dkms',
      kernel_module => 'proprietary',
      branch        => 580,
      packages      => [ 'kmod-nvidia-latest-dkms', 'nvidia-driver', 'nvidia-driver-cuda' ],
      verify        => [ 'nvidia-driver', 'kmod-nvidia-latest-dkms' ],
      pin_branch    => 580,
      $major >= 10 ? ( versionlock => '*nvidia*580*' ) : ( module_stream => '580-dkms' )
    }
  );
}

# karr #56, research of 2026-09-24 (rhel9 primary.xml): nvidia-fabric-manager
# (with the hyphen) for 570/575, nvidia-fabricmanager from 580 on. A fresh
# install always takes >= 580.
sub fabric_manager_package {
  my ( $self, $source ) = @_;
  my $pkg = $self->SUPER::fabric_manager_package($source);
  return $pkg unless defined $pkg && ( $source->{branch} // '' ) =~ /\A57[05]\z/;
  return 'nvidia-fabric-manager';
}

# nvlsm: CUDA repos rhel9 and rhel10 (2025.06.5 .. 2025.12.211); rpm Requires
# (libibumad or libibumad3). libibumad in BaseOS, infiniband-diags in
# AppStream on Rocky 9/10 (research 2026-09-24). NVIDIA's gpu-driver-container
# installs `infiniband-diags nvlsm` unversioned.
sub nvlink_fabric_packages { ( 'nvlsm', 'infiniband-diags', 'libibumad' ) }

sub nvlink_fabric_unavailable {
  my ( $self ) = @_;
  return if $self->major >= 9;
  return "nvlsm was verified in NVIDIA's CUDA repositories for RHEL 9 and 10 only, "
    .'not for release '.( $self->release // '' );
}

# NVIDIA's release notes list RHEL 9.6 (B200) and 9.8 (B300) -- kernel 5.14
# with backports -- as supported; maintainer decision (karr #56): no kernel
# warning on the RHEL family.
sub nvlink_kernel_backported { 1 }

sub plan {
  my ( $self ) = @_;
  my $plan = $self->SUPER::plan;
  $plan->{major} = $self->major;
  $plan->{rhel}  = $self->is_rhel;
  return $plan;
}


sub epel_release_url {
  my ( $self, $major ) = @_;
  return 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-'.$major.'.noarch.rpm';
}

# RHEL (karr #39): per EPEL's getting-started guide and NVIDIA's driver
# installation guide (RHEL 8/9/10 pre-installation steps), both checked
# 2026-09-24: subscription-manager enables CRB, EPEL comes from its release
# RPM URL. dkms: EPEL 8/9/10 carry it, repos/rhel{8,9,10}/x86_64 of the CUDA
# repo do not, and kmod-nvidia-{open,latest}-dkms Require it.
sub prepare_host {
  my ( $self, $plan ) = @_;
  Rex::Logger::info('  Enabling EPEL and extra repos...');
  if ($plan->{rhel}) {
    my $major = $plan->{major};
    $self->run_cmd($self->package_manager.' install -y '.$self->epel_release_url($major), auto_die => 0);
    $self->verify_packages({ verify => [ 'epel-release' ] });
    my $crb = 'codeready-builder-for-rhel-'.$major.'-'.$self->arch.'-rpms';
    $self->run_cmd('subscription-manager repos --enable '.$crb, auto_die => 0);
    Rex::Logger::info('  Could not enable '.$crb.' with subscription-manager; '
      .'EPEL packages that need CodeReady Builder will not install', 'warn')
      if $? != 0;
    return;
  }
  $self->install_helpers('epel-release');
  if ($plan->{major} >= 9) {
    $self->run_cmd('dnf config-manager --set-enabled crb 2>/dev/null || true', auto_die => 0);
  }
  else {
    $self->run_cmd('dnf config-manager --set-enabled powertools 2>/dev/null || true', auto_die => 0);
  }
}


sub prepare_source {
  my ( $self, $plan ) = @_;
  my $major = $plan->{major};

  # Arch-aware: aarch64 server/datacenter parts (Grace, Hopper, Blackwell) are
  # published under the "sbsa" tree, not "x86_64".
  my $distro = "rhel$major";
  my $arch   = $self->_cuda_repo_arch($self->arch);
  my $repo_url = "https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.repo";
  Rex::Logger::info("  Adding NVIDIA CUDA repo ($distro/$arch)...");
  # karr #47: on an HTTP error --add-repo writes no .repo and exits non-zero;
  # ignored, that only surfaced as "nvidia-driver not installed" after dnf
  # install. Die here, naming the URL and dnf's own words.
  my $out = $self->run_cmd("dnf config-manager --add-repo $repo_url 2>&1", auto_die => 0);
  if ($? != 0) {
    my $exit = $? >> 8;
    $out //= '';
    $out =~ s/\s+\z//;
    die "dnf config-manager --add-repo $repo_url failed (exit $exit)"
      . (length $out ? ": $out" : '')
      . "; no driver was installed\n";
  }
  $self->run_cmd('dnf clean expire-cache', auto_die => 0);

  my $source = $plan->{source} or return;
  if (my $stream = $source->{module_stream}) {
    if ($source->{stream_optional}) {
      $self->run_cmd("dnf module enable nvidia-driver:$stream -y 2>/dev/null || true", auto_die => 0);
    }
    else {
      # Pre-Turing (karr #26): unlike the open stream, a failed enable is NOT
      # swallowed: without it dnf would resolve the newest branch.
      $self->run_cmd("dnf module enable nvidia-driver:$stream -y", auto_die => 0);
      die "dnf module enable nvidia-driver:$stream failed — another "
        . "nvidia-driver stream is probably enabled already (`dnf module reset "
        . "nvidia-driver` switches it); no driver was installed\n"
        if $? != 0;
    }
  }
  if (my $lock = $source->{versionlock}) {
    $self->install_helpers('python3-dnf-plugin-versionlock');
    $self->run_cmd("dnf versionlock add '$lock'", auto_die => 0);
    die "dnf versionlock add '$lock' failed; no driver was installed\n"
      if $? != 0;
  }
}


sub verify_packages {
  my ( $self, $plan ) = @_;
  $self->SUPER::verify_packages($plan);
  my $branch = $plan->{source} && $plan->{source}{pin_branch} or return;
  my $version = $self->run_cmd("rpm -q --qf '%{VERSION}' nvidia-driver 2>&1", auto_die => 0);
  chomp $version if defined $version;
  die "nvidia-driver is " . ($version // 'unknown') . ", not branch "
    . "$branch — this pre-Turing GPU needs $branch\n"
    unless $self->_rpm_version_in_branch($version, $branch);
}


sub fabric_manager_version_unavailable {
  my ( $self, $pkg, $version ) = @_;
  my $out = $self->run_cmd("dnf -q list --showduplicates --available $pkg 2>/dev/null", auto_die => 0);
  return 'dnf list --showduplicates '.$pkg.' lists no version '.$version
    unless grep { $_ eq $version } $self->_dnf_list_versions($out, $pkg);
  return;
}

# Pure: the upstream versions of $pkg in `dnf list` output
# ("nvidia-fabricmanager.x86_64  3:580.95.05-1  cuda-rhel9-x86_64").
sub _dnf_list_versions {
  my ( $self, $out, $pkg ) = @_;
  my @versions;
  for my $line (split /\n/, $out // '') {
    my ( $na, $evr ) = split ' ', $line;
    next unless defined $evr && $na =~ /\A\Q$pkg\E\.[^.]+\z/;
    ( my $v = $evr ) =~ s/^\d+://;
    $v =~ s/-[^-]*$//;
    push @versions, $v;
  }
  return @versions;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Setup::RHEL - NVIDIA driver setup for RHEL, Rocky, AlmaLinux and CentOS Stream (experimental)

=head1 VERSION

version 0.002

=head1 DESCRIPTION

B<Experimental>, like L<Rex::GPU::NVIDIA::Setup>. The NVIDIA driver install
for the RHEL family (RHEL, Rocky Linux, AlmaLinux, CentOS Stream): EPEL and
CRB/PowerTools, NVIDIA's CUDA repository, the open-kernel DKMS driver by
default and the proprietary 580 kmod where the GPUs need it
(L</sources>), on the rpm layer L<Rex::GPU::NVIDIA::Setup::Rpm> with
C<dnf>.

=head2 major

The major version of the raw release string: C<10.1> is 10, never the
dot-stripped C<101> of C<operating_system_version>.

=head2 os_release

C</etc/os-release> as a hashref (C<ID>, C<ID_LIKE>, C<VERSION_ID>, ...; quotes
removed), read on first use with C<cat> through
L<Rex::GPU::NVIDIA::Setup/run_cmd>, or C<{}> when the file cannot be read.
Unless passed to C<new>.

=head2 is_rhel

True on Red Hat Enterprise Linux itself (C</etc/os-release> C<ID=rhel>), false
on Rocky, Alma, CentOS Stream and a host without C</etc/os-release>. The OS
name cannot tell: without C<lsb_release> Rex reports C<Redhat> for RHEL, Rocky
and Alma alike.

=head2 rex_pkg_works

True when L<Rex::Commands::Pkg/pkg> can work on this host: C<Rex::Pkg> picks
its provider through L<Rex::Commands::Gather/is_redhat>, and dies (C<OS/Provider
not supported>) on a name it does not know, such as C<Rocky> or C<AlmaLinux>
reported by C<lsb_release>.

=head2 install_helpers

  $self->install_helpers('python3-dnf-plugin-versionlock');

Installs inert helper packages: through L<Rex::GPU::NVIDIA::Setup/pkg_cmd>
where L</rex_pkg_works>, otherwise C<dnf install -y> run directly and
verified with C<rpm -q> (dies if one is missing).

=head2 kernel_packages

C<kernel-devel-matched> + C<kernel-headers> on 9 and later,
C<kernel-devel-$kernel> + C<kernel-headers> before.

=head2 sources

From NVIDIA's CUDA repository, in this order:

=over

=item * C<cuda-open-dkms> -- the open kernel module, the newest branch the
repository carries (at least 580). On 10 and later (no module streams
there): C<kmod-nvidia-open-dkms> + C<nvidia-driver> + C<nvidia-driver-cuda>.
Before 10: C<nvidia-open> from module stream C<nvidia-driver:open-dkms>,
whose enable may fail without harm.

=item * C<cuda-580-dkms> -- the proprietary kmod
(C<kmod-nvidia-latest-dkms>, C<nvidia-driver>, C<nvidia-driver-cuda>) held
on branch 580: module stream C<nvidia-driver:580-dkms> before 10, a
C<dnf versionlock> on C<*nvidia*580*> on 10 and later. Both the stream and
the lock must succeed (L</prepare_source>), and the installed
C<nvidia-driver> must be a 580 (L</verify_packages>).

=back

C<nvidia-driver> is verified on both, plus the proprietary kmod on the
second. On a host with NVSwitches both install C<nvidia-fabricmanager> of
the installed C<nvidia-driver>'s exact version
(C<dnf install -y nvidia-fabricmanager-VERSION>). So a GPU without constraints and Blackwell get C<cuda-open-dkms>,
Maxwell/Pascal/Volta C<cuda-580-dkms>.

On an HGX B200/B300 (L<Rex::GPU::NVIDIA::Setup/nvlink_fabric_needed>)
Fabric Manager is installed the same way, then C<nvlsm> from the same CUDA
repository and C<infiniband-diags> + C<libibumad> from the distribution
(L</nvlink_fabric_packages>).

=head2 fabric_manager_package

The base class's, except for driver branch 570 or 575 (only on an
already-installed driver, L<Rex::GPU::NVIDIA::Setup/retrofit_fabric_manager>):
there NVIDIA's CUDA repository names it C<nvidia-fabric-manager>.

=head2 nvlink_fabric_packages

C<nvlsm>, C<infiniband-diags>, C<libibumad>, unversioned (see
L<Rex::GPU::NVIDIA::Setup/nvlink_fabric_packages>): C<nvlsm> from NVIDIA's
CUDA repository, the other two from BaseOS / AppStream.

=head2 nvlink_fabric_unavailable

A reason below RHEL 9: C<nvlsm> was checked in the C<rhel9> and C<rhel10>
repositories only.

=head2 nvlink_kernel_backported

True: NVIDIA supports HGX B200/B300 on RHEL 9.6/9.8 with its 5.14 kernel, so
no kernel warning on the RHEL family.

=head2 plan

The base plan plus C<< $plan->{major} >> and C<< $plan->{rhel} >>
(L</is_rhel>, which reads C</etc/os-release>) for the later steps. Reads no
architecture: C<uname -m> runs in L</prepare_source>, after EPEL and CRB are
enabled, as it always did -- on RHEL itself in L</prepare_host>, which needs
it for the CodeReady Builder repository name.

=head2 prepare_host

Enables EPEL, which C<dkms> comes from (the NVIDIA kmod packages require it;
neither the CUDA repository nor the distribution carries it), and the
CodeReady Builder repository EPEL packages may depend on:

=over

=item * Rocky, Alma, CentOS Stream: C<epel-release> through
L</install_helpers>, then C<crb> (9 and later) or C<powertools> (before 9)
with C<dnf config-manager>; a failure there is ignored.

=item * RHEL itself (L</is_rhel>), which has no C<epel-release> package: EPEL's
release RPM, C<dnf install -y
https://dl.fedoraproject.org/pub/epel/epel-release-latest-MAJOR.noarch.rpm>,
verified with C<rpm -q epel-release> (dies if missing); then
C<subscription-manager repos --enable
codeready-builder-for-rhel-MAJOR-ARCH-rpms> (C<uname -m>), which warns on
failure but does not die -- a host without subscription-manager (RHUI) names
the repository differently.

=back

=head2 epel_release_url

  my $url = $setup->epel_release_url(9);

EPEL's release RPM for a RHEL major version.

=head2 prepare_source

Adds NVIDIA's CUDA repository C<rhelN> for the host architecture (read here,
C<uname -m>: aarch64 is the C<sbsa> tree) with C<dnf config-manager
--add-repo>; if that exits non-zero (e.g. the C<.repo> URL answers with an
HTTP error, so nothing was written) it B<dies> with the URL and dnf's output,
before any driver package is installed. Then it expires dnf's cache and selects
the driver branch the chosen source asks for:

=over

=item * C<module_stream>: C<dnf module enable nvidia-driver:STREAM -y>. For
C<cuda-580-dkms> a failure B<dies> here, before any driver package is
installed -- without the pin dnf would resolve the newest branch, which does
not support the GPU; for C<cuda-open-dkms> (C<stream_optional>) it is
ignored.

=item * C<versionlock>: C<python3-dnf-plugin-versionlock> (L</install_helpers>), then
C<dnf versionlock add>; a failure dies the same way.

=back

=head2 verify_packages

The rpm layer's C<rpm -q> check, then for a source with C<pin_branch>
(C<cuda-580-dkms>): dies unless the installed C<nvidia-driver> is on that
branch (C<rpm -q --qf '%{VERSION}'>), not a newer one that cannot drive the
GPU.

=head2 fabric_manager_version_unavailable

Host-read-only: C<dnf list --showduplicates --available PKG> must list a
version whose upstream part (no epoch, no release) is C<$version>. dnf
refreshes expired metadata on its own, as for a fresh install; no
repository is added or enabled. C<dnf install> never removes a package
without C<--allowerasing>, so no simulation is needed before
L<Rex::GPU::NVIDIA::Setup::Rpm/install_versioned_package>.

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
