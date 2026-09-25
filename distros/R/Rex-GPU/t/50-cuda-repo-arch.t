use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit test for the RHEL/RHEL-like NVIDIA CUDA-repo architecture mapping.
#
# The RHEL branch of install_driver fetches
#   developer.download.nvidia.com/compute/cuda/repos/<distro>/<arch>/cuda-<distro>.repo
# and used to hardcode <arch> = x86_64, which on aarch64 pointed at a repo that
# does not exist for that machine. NVIDIA publishes aarch64 server/datacenter
# parts (Grace, Hopper, Blackwell) under the "sbsa" tree, verified live:
#   repos/rhel9/sbsa  and  repos/rhel10/sbsa  resolve (HTTP 200)
#   repos/.../aarch64 does NOT (that token is the libnvidia-container toolkit
#   repo's convention, not the CUDA repo's).
#
# _cuda_repo_arch($machine) is pure (string map only, no run/dnf), so it is
# unit-testable offline. The live dnf install against a real RHEL aarch64 node
# is NOT exercised here — a maintainer must run it; a green prove is not
# evidence it works. See the t/10-detect.t header for the wider
# "what prove cannot see".
# -----------------------------------------------------------------------------

use Rex::GPU::NVIDIA;

sub arch { Rex::GPU::NVIDIA::_cuda_repo_arch(@_) }

subtest 'aarch64 => sbsa' => sub {
  is(arch('aarch64'), 'sbsa', 'uname -m aarch64 => sbsa (CUDA repo token)');
  is(arch('arm64'),   'sbsa', 'arm64 spelling => sbsa too');
};

subtest 'x86_64 and fallbacks => x86_64 (unchanged behaviour)' => sub {
  is(arch('x86_64'), 'x86_64', 'x86_64 => x86_64');
  is(arch(''),       'x86_64', 'empty (uname -m unreadable) => x86_64 fallback');
  is(arch(undef),    'x86_64', 'undef => x86_64 fallback');
  # Any other machine keeps the prior x86_64 default rather than inventing a
  # repo token this distribution has never supported.
  is(arch('ppc64le'), 'x86_64', 'unsupported machine => x86_64 (prior behaviour)');
};

done_testing;
