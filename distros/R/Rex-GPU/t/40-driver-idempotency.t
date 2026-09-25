use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit test for the install_driver idempotency short-circuit (karr #10).
#
# Regression guard: on a host already provisioned with a working NVIDIA driver
# (e.g. via the NVIDIA CUDA apt repo -- cuda-drivers / unversioned nvidia-driver
# userspace; verified live on otho-lab: working 610.57.04, RTX 3090), the Ubuntu
# branch auto-selected a versioned nvidia-driver-NNN-server whose libs Conflict
# with the installed userspace. apt refused (held broken packages) and gpu_setup
# died at the install-verify seam; the picked version could also be LOWER than
# the installed one (a downgrade). install_driver now short-circuits BEFORE the
# per-distro package selection when a working driver is already loaded.
#
# _nvidia_driver_present($smi_output) is the pure decision (regex on the text of
# `nvidia-smi -L`, no run/apt/dpkg) so it is unit-testable offline. The live
# skip path — that install_driver actually returns without touching apt and
# without writing the nouveau blacklist / rebooting — is NOT exercised here: a
# maintainer must run install_driver on a real node; a green prove is not
# evidence it works. See the t/10-detect.t header for the wider "what prove
# cannot see".
#
# CLAIM asserted by these tests:
#   * `nvidia-smi -L` output that lists a "GPU N:" device => driver present (skip)
#   * every failure form (NVML mismatch, no devices, command not found, empty,
#     undef) => driver NOT present (proceed with install)
# -----------------------------------------------------------------------------

use Rex::GPU::NVIDIA;

sub present { Rex::GPU::NVIDIA::_nvidia_driver_present(@_) }

subtest 'working driver => present (skip install)' => sub {
  # The exact `nvidia-smi -L` line from otho-lab (Ubuntu 24.04, 610.57.04).
  is(present('GPU 0: NVIDIA GeForce RTX 3090 (UUID: GPU-52a33d05-e8b1-1512-dadf-84e7834502f6)'),
    1, 'single GPU listed => present');
  is(present("GPU 0: NVIDIA RTX 4000 SFF Ada Generation (UUID: GPU-aaa)\n"
           . "GPU 1: NVIDIA RTX 4000 SFF Ada Generation (UUID: GPU-bbb)"),
    1, 'multiple GPUs listed => present');
};

subtest 'no working driver => not present (proceed with install)' => sub {
  is(present('Failed to initialize NVML: Driver/library version mismatch'),
    0, 'NVML init failure => not present');
  is(present('No devices were found'), 0, 'no devices => not present');
  is(present('bash: nvidia-smi: command not found'), 0, 'binary missing => not present');
  is(present(''),    0, 'empty output => not present');
  is(present(undef), 0, 'undef output => not present');
};

done_testing;
