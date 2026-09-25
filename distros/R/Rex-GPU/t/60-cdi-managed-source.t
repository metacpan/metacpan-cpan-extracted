use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit test for the generate_cdi_specs managed-CDI-source short-circuit (karr #11).
#
# Modern nvidia-container-toolkit ships nvidia-cdi-refresh.path/.service, which
# regenerate /run/cdi/nvidia.yaml and keep it fresh across driver updates.
# /etc/cdi and /run/cdi are BOTH default CDI scan dirs, so the old
# generate_cdi_specs — which always wrote a static /etc/cdi/nvidia.yaml —
# defined the same device kind (nvidia.com/gpu) twice when the managed source
# was also present (a duplicate-device load error in CDI consumers), and the
# static copy drifted against the refreshed /run/cdi copy over driver updates.
#
# _cdi_managed_source_present(%signals) is the pure decision (regex/string/
# boolean on gathered systemctl + test output, no run/systemctl/test) so it is
# unit-testable offline, like _nvidia_driver_present / _containerd_nvidia_action.
#
# WHAT THIS TEST DOES NOT COVER — and it is NOT hardware-verified. The live
# behaviour is NOT exercised here: that generate_cdi_specs actually SKIPS the
# /etc/cdi write, triggers the managed generator, and that a real node then
# loads a single nvidia.com/gpu. It could not be: the toolkit/CDI step was never
# run live — the otho-lab pipeline died at the driver step (karr #7) — so this
# change has not touched real hardware. A maintainer MUST run generate_cdi_specs
# on a real node that has nvidia-cdi-refresh installed and confirm that:
#   * /etc/cdi/ is NOT written (stays empty / absent), and
#   * /run/cdi/nvidia.yaml is present and fresh after the run, and
#   * the CDI consumer (device plugin) loads nvidia.com/gpu exactly ONCE.
# A green prove is NOT evidence any of that works. See the t/10-detect.t header
# for the wider "what prove cannot see".
#
# CLAIM asserted by these tests:
#   * nvidia-cdi-refresh.path installed (is-enabled enabled/static/...) => managed (skip /etc/cdi)
#   * nvidia-cdi-refresh.path armed     (is-active active/activating)   => managed (skip)
#   * a /run/cdi/nvidia.yaml already present                            => managed (skip)
#   * unit disabled/masked/not-found/inactive AND no /run/cdi file      => NOT managed (write /etc/cdi)
# -----------------------------------------------------------------------------

use Rex::GPU::NVIDIA;

sub managed { Rex::GPU::NVIDIA::_cdi_managed_source_present(@_) }

subtest 'refresh unit installed (is-enabled) => managed, skip /etc/cdi' => sub {
  is(managed(enabled_state => 'enabled'),         1, 'enabled => managed');
  is(managed(enabled_state => 'enabled-runtime'), 1, 'enabled-runtime => managed');
  is(managed(enabled_state => 'static'),          1, 'static (toolkit .path unit, no [Install]) => managed');
  is(managed(enabled_state => 'indirect'),        1, 'indirect => managed');
  is(managed(enabled_state => 'alias'),           1, 'alias => managed');
  is(managed(enabled_state => "static\n"),        1, 'trailing newline tolerated');
};

subtest 'refresh unit armed (is-active) => managed, skip /etc/cdi' => sub {
  is(managed(active_state => 'active'),     1, 'active watcher => managed');
  is(managed(active_state => 'activating'), 1, 'activating => managed');
};

subtest '/run/cdi/nvidia.yaml already present => managed (external producer)' => sub {
  # Only some OTHER producer can have written /run/cdi/nvidia.yaml: this code has
  # only ever written /etc/cdi, so its presence is unambiguous evidence of a
  # second CDI source for the same kind. Catches a managed producer under a
  # different unit name, or a host where systemctl is unavailable.
  is(managed(run_cdi => 1), 1, '/run/cdi/nvidia.yaml present => managed');
  is(managed(enabled_state => 'not-found', active_state => 'inactive', run_cdi => 1),
    1, 'file present overrides a not-found/inactive unit');
};

subtest 'no managed source => NOT managed, write /etc/cdi as before' => sub {
  is(managed(),                             0, 'no signals => not managed');
  is(managed(enabled_state => 'disabled'),  0, 'disabled (user opted out) => not managed');
  is(managed(enabled_state => 'masked'),    0, 'masked => not managed');
  is(managed(enabled_state => 'not-found'), 0, 'not-found (no such unit) => not managed');
  is(managed(active_state  => 'inactive'),  0, 'inactive => not managed');
  is(managed(active_state  => 'failed'),    0, 'failed => not managed');
  is(managed(active_state  => 'unknown'),   0, 'unknown => not managed');
  is(managed(enabled_state => '', active_state => '', run_cdi => 0),
    0, 'empty systemctl output (non-systemd host) + no file => not managed');
  # "disabled" must not be rescued by "enabled" matching as a prefix/substring.
  is(managed(enabled_state => 'disabled', active_state => 'inactive'),
    0, 'disabled is not matched by the enabled/... allowlist');
};

done_testing;
