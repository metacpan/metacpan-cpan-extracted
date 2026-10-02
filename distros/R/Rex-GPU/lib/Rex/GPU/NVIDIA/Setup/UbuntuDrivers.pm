# ABSTRACT: NVIDIA driver setup for Ubuntu, package named by ubuntu-drivers (experimental)

package Rex::GPU::NVIDIA::Setup::UbuntuDrivers;
our $VERSION = '0.004';
use Moo;
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';


sub prepare_source {
  my ( $self, $plan ) = @_;
  $self->SUPER::prepare_source($plan);
  return unless defined( ( $plan->{source} // {} )->{search} );
  $self->run_cmd('command -v ubuntu-drivers >/dev/null || DEBIAN_FRONTEND=noninteractive '
    .$self->apt_get.' install -y --no-upgrade ubuntu-drivers-common', auto_die => 0);
  return;
}


sub resolve_source {
  my ( $self, $source ) = @_;
  return $self->SUPER::resolve_source($source) unless defined $source->{search};
  my $open   = $source->{kernel_module} eq 'open' ? 1 : 0;
  my $wanted = $open ? 'nvidia-driver-NNN-server-open' : 'nvidia-driver-NNN-server';
  $self->run_cmd('command -v ubuntu-drivers >/dev/null', auto_die => 0);
  return { %$source, unavailable => 'ubuntu-drivers is not installed (installing '
    .'ubuntu-drivers-common failed), so nothing names the '.$wanted.' package' }
    if $? != 0;
  my $list = $self->run_cmd('ubuntu-drivers list --gpgpu 2>/dev/null', auto_die => 0);
  my $rc = $? >> 8;
  return { %$source, unavailable => 'ubuntu-drivers list --gpgpu failed (exit '.$rc.')' }
    if $? != 0;
  my ( $package, $branch );
  for my $line (split /\n/, $list // '') {
    my ( $name, $b, $is_open ) = $line =~ /^\s*(nvidia-driver-(\d+)-server(-open)?)(?=,|\s|\z)/
      or next;
    next unless ( $is_open ? 1 : 0 ) == $open;
    ( $package, $branch ) = ( $name, $b ) if !defined $branch || $b > $branch;
  }
  return { %$source, unavailable => 'ubuntu-drivers list --gpgpu names no '.$wanted
    .' package for this GPU' }
    unless defined $package;
  my %resolved = ( %$source, packages => [ $package ], verify => [ $package ], branch => $branch );
  delete $resolved{branch_at_least};
  return \%resolved;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Setup::UbuntuDrivers - NVIDIA driver setup for Ubuntu, package named by ubuntu-drivers (experimental)

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Rex::GPU;

  # per call
  gpu_setup(setup => 'Rex::GPU::NVIDIA::Setup::UbuntuDrivers');

  # or for the whole Rexfile -- also reaches Rex::Rancher's gpu => 1
  set gpu_nvidia_setup => 'Rex::GPU::NVIDIA::Setup::UbuntuDrivers';

=head1 DESCRIPTION

B<Experimental>, like L<Rex::GPU::NVIDIA::Setup>. B<Opt-in>: the Ubuntu
default (L<Rex::GPU::NVIDIA/setup_class_for_os>) stays
L<Rex::GPU::NVIDIA::Setup::Ubuntu>; this class is used only when chosen
with the C<setup> option or C<set gpu_nvidia_setup>. For Ubuntu hosts only.

The driver package is named by Ubuntu's own C<ubuntu-drivers list --gpgpu>
instead of C<apt-cache search> for the newest C<-server> package
(L</resolve_source>). Everything else is inherited from
L<Rex::GPU::NVIDIA::Setup::Ubuntu>: which source fits the GPUs (C<-server>,
C<-server-open>, the pinned 580 for Maxwell/Pascal/Volta), the requirement
check of the named package, the running kernel's headers only, the dpkg
lock timeout, the apt timer stop, and the driver install itself --
C<apt-get install> directly, verified with C<dpkg -l>. C<ubuntu-drivers
install> is never run: its package choice and exit code could not be
verified.

=head2 prepare_source

The inherited step (C<apt-get update>), then -- only when the chosen source
is resolved by L</resolve_source>, i.e. carries a C<search> pattern --
C<ubuntu-drivers-common> unless C<ubuntu-drivers> is already on the
C<PATH>. An inert helper: C<apt-get install -y --no-upgrade> with the dpkg
lock timeout and C<auto_die =E<gt> 0>, not verified here; if the command is
still missing, L</resolve_source> says so and the install dies before any
driver package.

=head2 resolve_source

For a source with a C<search> pattern (C<ubuntu-server>, C<ubuntu-server-open>,
see L<Rex::GPU::NVIDIA::Setup::Ubuntu/sources>): C<ubuntu-drivers list
--gpgpu>, read-only (it reads the GPU modaliases in sysfs and the apt index,
it installs nothing), names the package. Of the lines it prints --
C<nvidia-driver-NNN-server> or C<nvidia-driver-NNN-server-open>, optionally
followed by C<, (kernel modules provided by ...)> -- the one with the
highest NNN of the source's kernel module flavour is taken; returns the
source with that one package (installed and verified) and its branch.

Makes the source C<unavailable>, so that
L<Rex::GPU::NVIDIA::Setup/resolve_plan> dies before any driver package is
installed, when:

=over

=item * C<ubuntu-drivers> is not on the C<PATH> (the
C<ubuntu-drivers-common> install of L</prepare_source> failed);

=item * C<ubuntu-drivers list --gpgpu> exits non-zero;

=item * it names no package of the source's flavour.

=back

There is no fallback to C<apt-cache search> and no other source is tried.
The package it names is checked against the GPUs' requirement like any
other (a Blackwell still refuses a proprietary package). Any other source
(the pinned C<ubuntu-server-580>) resolves as in
L<Rex::GPU::NVIDIA::Setup::Ubuntu/resolve_source>, with its candidate
check.

=head1 SEE ALSO

L<Rex::GPU::NVIDIA::Setup::Ubuntu>, L<Rex::GPU::NVIDIA::Setup>,
L<Rex::GPU::NVIDIA/install_driver>

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
