package My::GPU::UbuntuDrivers;
# Example custom NVIDIA driver setup for Rex::GPU (experimental Setup API):
# let Ubuntu's own `ubuntu-drivers list --gpgpu` name the driver package
# instead of Rex::GPU's `apt-cache search` for the newest -server package.
#
# Ubuntu hosts only -- it extends the Ubuntu setup and overrides one step,
# resolve_source (plus a helper install in prepare_source). Unchanged and
# inherited: which source fits the GPUs (-server, -server-open, the pinned
# 580 for pre-Turing), the requirement check of the package it names (a
# Blackwell still refuses a proprietary package), the dpkg lock timeout, the
# apt-timer stop, the direct apt-get install and the dpkg -l verification.
#
# `ubuntu-drivers list --gpgpu` only READS (the GPU modaliases in sysfs and
# the apt index); it never installs. The package it names is installed by the
# inherited install_packages -- not by `ubuntu-drivers install`, whose exit
# code and package choice Rex::GPU could not verify.
use Moo;
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';

# After the inherited step (apt timers stopped, apt-get update): make sure
# ubuntu-drivers is there. ubuntu-drivers-common is an inert helper; it goes
# through apt-get with the lock timeout like everything else here.
sub prepare_source {
  my ( $self, $plan ) = @_;
  $self->SUPER::prepare_source($plan);
  $self->run_cmd('command -v ubuntu-drivers >/dev/null || DEBIAN_FRONTEND=noninteractive '
    .$self->apt_get.' install -y ubuntu-drivers-common', auto_die => 0);
}

# The sources with a `search` pattern (ubuntu-server, ubuntu-server-open) are
# resolved from ubuntu-drivers' list: the newest nvidia-driver-NNN-server
# package of the source's kernel module flavour. Everything else (the pinned
# 580 source) resolves as it does upstream.
#
# ubuntu-drivers list prints one package per line, optionally followed by
# ", (kernel modules provided by linux-modules-nvidia-...)".
sub resolve_source {
  my ( $self, $source ) = @_;
  return $self->SUPER::resolve_source($source) unless defined $source->{search};
  my $open = $source->{kernel_module} eq 'open' ? 1 : 0;
  my $list = $self->run_cmd('ubuntu-drivers list --gpgpu 2>/dev/null', auto_die => 0);
  my ( $package, $branch );
  for my $line (split /\n/, $list // '') {
    my ( $name, $b, $is_open ) = $line =~ /^\s*(nvidia-driver-(\d+)-server(-open)?)(?=,|\s|\z)/
      or next;
    next unless ( $is_open ? 1 : 0 ) == $open;
    ( $package, $branch ) = ( $name, $b ) if !defined $branch || $b > $branch;
  }
  return { %$source, unavailable => 'ubuntu-drivers list --gpgpu names no '
    .( $open ? 'nvidia-driver-NNN-server-open' : 'nvidia-driver-NNN-server' ).' package for this GPU' }
    unless defined $package;
  my %resolved = ( %$source, packages => [ $package ], verify => [ $package ], branch => $branch );
  delete $resolved{branch_at_least};
  return \%resolved;
}

1;
