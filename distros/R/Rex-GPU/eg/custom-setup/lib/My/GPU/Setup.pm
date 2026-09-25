package My::GPU::Setup;
# Example custom NVIDIA driver setup for Rex::GPU (experimental Setup API).
#
# Lives in the project's lib/ next to the Rexfile: Rex puts that directory on
# @INC, so `set gpu_nvidia_setup => 'My::GPU::Setup'` or
# `gpu_setup(setup => 'My::GPU::Setup')` finds it without touching Rex::GPU.
#
# Ubuntu hosts only -- it extends the Ubuntu setup. Two changes:
#   1. a pinned source ahead of the built-in ones: the open 580 LTS driver;
#   2. an optional extra apt line (a local mirror) before `apt-get update`.
# Everything else -- the dpkg lock timeout, the apt-timer stop, the direct
# apt-get install and the dpkg -l verification -- is inherited.
use Moo;
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';

# e.g. 'deb [signed-by=/usr/share/keyrings/internal.gpg] http://apt.internal.example/ubuntu noble main restricted'
has apt_line => ( is => 'ro', predicate => 1 );

# Tried first. The GPUs' requirement still decides: a Turing-to-Blackwell GPU
# takes it, a V100 (proprietary only) or a GPU that needs a newer branch
# rejects it and falls through to the built-in sources below.
sub sources {
  my ( $self ) = @_;
  return (
    {
      name            => 'pinned-580-open',
      kernel_module   => 'open',
      branch          => 580,
      packages        => [ 'nvidia-driver-580-server-open' ],
      verify          => [ 'nvidia-driver-580-server-open' ],
      check_candidate => 'nvidia-driver-580-server-open'
    },
    $self->SUPER::sources
  );
}

# The mirror goes in before the inherited step runs `apt-get update`; the
# candidate check of check_candidate above runs after it (resolve_source).
sub prepare_source {
  my ( $self, $plan ) = @_;
  if ($self->has_apt_line) {
    $self->file_cmd('/etc/apt/sources.list.d/internal-nvidia.list',
      content => $self->apt_line."\n");
  }
  $self->SUPER::prepare_source($plan);
}

1;
