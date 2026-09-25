# ABSTRACT: NVIDIA driver setup for openSUSE Leap (experimental)

package Rex::GPU::NVIDIA::Setup::SUSE;
our $VERSION = '0.002';
use Moo;
use Rex::Logger ();
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup::Rpm';


sub package_manager { 'zypper' }


sub zypper_lock_timeout { 120 }

sub zypper {
  my ( $self ) = @_;
  return 'ZYPP_LOCK_TIMEOUT='.$self->zypper_lock_timeout.' zypper';
}

sub package_manager_command {
  my ( $self ) = @_;
  return $self->zypper;
}


sub leap_version {
  my ( $self ) = @_;
  my $release = $self->release;
  return '16.0' if $self->_major_version($release) >= 16;
  my ($leap_version) = ($release // '') =~ /^(\d+\.\d+)/;
  return $leap_version // $release;
}

sub repo_url {
  my ( $self, $leap_version ) = @_;
  return "https://download.nvidia.com/opensuse/leap/$leap_version/";
}

# G06 is NVIDIA's series up to 580, G07 the open-only one after it. Checked
# 2026-09-23 in the repos' primary.xml: the G06 metas (open on leap/15.6,
# proprietary on 15.6 and 16.0) carry branches 570 and 580 only, zypper
# resolves the newest, so they install 580 -- branch 580 exactly; 590 never
# went into G06. The G07 open meta on leap/16.0 carries 594 and 595, newer
# branches land there: branch_at_least 595. NVIDIA's leap/15.6/ and leap/16.0/ repos
# both carry nvidia-driver-G06-kmp-meta (x86_64 + aarch64, up to 580.178.04,
# checked in their primary.xml 2026-09-23); it requires
# nvidia-driver-G06-kmp and nvidia-userspace-meta-G06 at its own exact
# version. The open G06/G07 metas do not support pre-Turing GPUs.
#
# Verification (karr #27), from the same primary.xml (x86_64, 2026-09-23):
# every meta requires the capability "<kmp> = <its version>" plus
# nvidia-userspace-meta-G0x. nvidia-driver-G06-kmp is provided by
# nvidia-driver-G06-kmp-default / -64kb (NVIDIA's repo); the
# nvidia-open-driver-G0x-signed-kmp capability by no package in NVIDIA's
# repo -- the signed kmp comes from openSUSE's own repositories. rpm -q of
# the meta alone would trust that libzypp, which commits package by package
# and resolves dependencies itself, never leaves a meta without its kmp; the
# capability query checks it, flavour-independent.
sub sources {
  my ( $self ) = @_;
  my $url = $self->repo_url($self->leap_version);
  my $open = $self->_major_version($self->release) >= 16
    ? { name => 'nvidia-gfx-G07-open', branch_at_least => 595,
        packages => [ 'nvidia-open-driver-G07-signed-kmp-meta' ],
        verify   => [ 'nvidia-open-driver-G07-signed-kmp-meta', 'nvidia-open-driver-G07-signed-kmp' ] }
    : { name => 'nvidia-gfx-G06-open', branch => 580,
        packages => [ 'nvidia-open-driver-G06-signed-kmp-meta' ],
        verify   => [ 'nvidia-open-driver-G06-signed-kmp-meta', 'nvidia-open-driver-G06-signed-kmp' ] };
  return (
    { %$open, kernel_module => 'open', repo_url => $url },
    {
      name          => 'nvidia-gfx-G06',
      kernel_module => 'proprietary',
      branch        => 580,
      packages      => [ 'nvidia-driver-G06-kmp-meta' ],
      verify        => [ 'nvidia-driver-G06-kmp-meta', 'nvidia-driver-G06-kmp' ],
      repo_url      => $url
    }
  );
}

sub verify_query {
  my ( $self, $what ) = @_;
  return 'rpm -q --whatprovides '.$what;
}

sub plan {
  my ( $self ) = @_;
  my $plan = $self->SUPER::plan;
  $plan->{repo_url} = $plan->{source} && $plan->{source}{repo_url};
  return $plan;
}


sub prepare_host {
  my ( $self, $plan ) = @_;
  Rex::Logger::info('  Removing any existing NVIDIA packages...');
  $self->run_cmd(q{rpm -e $(rpm -qa | grep -E '^(nvidia|libnvidia)' | grep -v 'container') 2>/dev/null || true},
    auto_die => 0);
}


sub prepare_source {
  my ( $self, $plan ) = @_;
  Rex::Logger::info('  Adding NVIDIA GFX repo (Leap '.$self->release.'): '.$plan->{repo_url});
  $self->add_repo('nvidia-gfx', $plan->{repo_url});
}


sub add_repo {
  my ( $self, $alias, $url ) = @_;
  # karr #52: both exit codes used to be ignored. rr first keeps re-runs from
  # tripping over addrepo's "already exists" (exit 4).
  $self->run_cmd($self->zypper.' rr '.$alias.' 2>/dev/null || true', auto_die => 0);
  my $out = $self->run_cmd($self->zypper.' addrepo --refresh '.$url.' '.$alias.' 2>&1', auto_die => 0);
  $self->_die_zypper_repo('addrepo', $alias, $url, $out) if $? != 0;
  $out = $self->run_cmd($self->zypper.' --gpg-auto-import-keys refresh '.$alias.' 2>&1', auto_die => 0);
  return if $? == 0;
  my $exit = $?;
  $self->run_cmd($self->zypper.' rr '.$alias.' 2>/dev/null || true', auto_die => 0);
  $? = $exit;
  $self->_die_zypper_repo('refresh', $alias, $url, $out);
}

sub _die_zypper_repo {
  my ( $self, $step, $alias, $url, $out ) = @_;
  my $exit = $? >> 8;
  $out //= '';
  $out =~ s/\s+\z//;
  die 'zypper '.$step.' of repository '.$alias.' ('.$url.') failed (exit '.$exit.')'
    .(length $out ? ': '.$out : '')
    .($step eq 'refresh' ? '; the repository was removed again' : '')
    ."; nothing was installed from it\n";
}


sub install_packages {
  my ( $self, $plan ) = @_;
  $self->SUPER::install_packages($plan);
  $self->run_cmd($self->zypper.' addlock libnvidia-ml libnvidia-cfg 2>/dev/null || true', auto_die => 0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Setup::SUSE - NVIDIA driver setup for openSUSE Leap (experimental)

=head1 VERSION

version 0.002

=head1 DESCRIPTION

B<Experimental>, like L<Rex::GPU::NVIDIA::Setup>. The NVIDIA driver install
for openSUSE Leap 15 and 16: the signed kmp meta package from NVIDIA's GFX
repository, on the rpm layer L<Rex::GPU::NVIDIA::Setup::Rpm> with
C<zypper>. openSUSE is not a verified deploy target of Rex::GPU.

There is no separate zypper packaging layer: besides the install command
name (L</package_manager>) everything zypper-specific here -- the GFX
repository, the stale-package purge, the library lock -- belongs to this one
driver install.

=head2 package_manager

C<zypper>.

=head2 zypper_lock_timeout

Seconds every C<zypper> of this class waits for the zypp lock
(C<ZYPP_LOCK_TIMEOUT>). Default C<120>, like the apt layer's
L<Rex::GPU::NVIDIA::Setup::Apt/apt_lock_timeout>: on a fresh boot cloud-init
can still hold it, and zypper otherwise fails at once with exit 7. A method,
not an attribute, so it also answers on the class (L</add_repo> is called
on it); override it in a subclass.

=head2 zypper

  $self->zypper            # "ZYPP_LOCK_TIMEOUT=120 zypper"

The C<zypper> invocation every command of this class starts with, and its
L<Rex::GPU::NVIDIA::Setup::Rpm/package_manager_command>. A lock still held
after L</zypper_lock_timeout> fails the command with exit 7 as before.

=head2 sources

One kmp meta package from NVIDIA's GFX repository for the Leap release
(key C<repo_url>, see L</leap_version>), in this order:

=over

=item * Leap 16: C<nvidia-gfx-G07-open> --
C<nvidia-open-driver-G07-signed-kmp-meta>, open kernel module, the newest
G07 branch (at least 595). Leap 15: C<nvidia-gfx-G06-open> --
C<nvidia-open-driver-G06-signed-kmp-meta>, open, branch 580.

=item * C<nvidia-gfx-G06> -- the proprietary C<nvidia-driver-G06-kmp-meta>,
branch 580 (G07 has no proprietary module), on Leap 15 and 16.

=back

None names a Fabric Manager: NVIDIA's GFX repository has none (it is only
in the CUDA repository), so a host with NVSwitches
(L<Rex::GPU::NVIDIA::Setup/nvswitches>) dies in
L<Rex::GPU::NVIDIA::Setup/plan>, before it is changed.

A meta package co-installs the kernel module and the userspace at one
version, so C<nvidia-smi> never sees a C<Driver/library version mismatch>.
Pre-signed kmp packages need no kernel headers.

Every source verifies two entries after the install (L</verify_query>): the
meta package, and the kernel module package it requires -- the capability
C<nvidia-open-driver-G06-signed-kmp> / C<nvidia-open-driver-G07-signed-kmp>
/ C<nvidia-driver-G06-kmp>, whichever kernel flavour (C<-default>,
C<-64kb>, ...) provides it. Either missing dies with the rpm layer's
C<... not installed after zypper install> message. That the module builds,
loads and binds is left to L<Rex::GPU::NVIDIA/verify_nvidia>.

=head2 verify_query

C<rpm -q --whatprovides NAME>: a package provides its own name, so the meta
package passes as before, and the kmp capability passes whichever flavour
package carries it.

=head2 leap_version

C<16.0> on Leap 16 and later, the C<x.y> of the raw release string
(C<15.6>) before -- never C<operating_system_version>, which strips the dots
(C<156>, karr #6).

=head2 repo_url

  my $url = $self->repo_url('15.6');

C<https://download.nvidia.com/opensuse/leap/15.6/>.

=head2 plan

The base plan plus C<< $plan->{repo_url} >>, the chosen source's repository.

=head2 prepare_host

Removes (C<rpm -e>) every installed C<nvidia*> / C<libnvidia*> package except
the container toolkit's: C<libnvidia-ml> / C<libnvidia-cfg> from the OSS
non-free repository lag behind the GFX repository's kmp and split the
driver from its libraries.

=head2 prepare_source

(Re-)adds NVIDIA's GFX repository as C<nvidia-gfx> by its base URL (zypper
cannot parse the yum C<.repo> files) and refreshes it, importing its key --
see L</add_repo>, which dies before any driver package is installed if the
repository cannot be added or refreshed.

=head2 add_repo

  $setup->add_repo('nvidia-gfx', 'https://download.nvidia.com/opensuse/leap/15.6/');

Replaces the zypper repository C<ALIAS> with one for C<URL>: C<zypper rr
ALIAS> (a missing alias is fine), C<zypper addrepo --refresh URL ALIAS>,
then C<zypper --gpg-auto-import-keys refresh ALIAS>. An existing entry is
always replaced, never kept, so a re-run -- or a host upgraded to a Leap
release with another URL -- ends up with this URL.

Each of them waits up to L</zypper_lock_timeout> for the zypp lock.
B<Dies> if C<addrepo> exits non-zero (after the C<rr> that happens only for
a real error, e.g. the zypp lock still held after that wait, exit 7), naming
alias, URL, exit code and zypper's output. C<addrepo> of a base URL does not
contact the server, so an HTTP error or an unresolvable host shows only in
the C<refresh> (exit 4, "Repository ... is invalid"): then the entry just
added is removed again -- an enabled, broken repository would make every
later zypper command on the host exit 106 -- and it dies the same way.
Used by L<Rex::GPU::NVIDIA/install_container_toolkit> too.

=head2 install_packages

The rpm layer's C<zypper install -y>, then C<zypper addlock libnvidia-ml
libnvidia-cfg>, so a later C<zypper update> cannot pull the stale OSS
non-free libraries back in and cause the version mismatch again.

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
