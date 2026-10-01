use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit test for the RKE2/K3s containerd clobber-HEAL decision (karr #13).
#
# rex-gpu 0.002 (pre-karr #9) wrote a bare full-config config.toml.tmpl --
# literally:
#     imports = ["/etc/containerd/conf.d/*.toml"]
#     version = 2
# -- that REPLACED the RKE2/K3s base config (no `{{ template "base" . }}`, so
# the rendered config.toml lost SystemdCgroup / the pinned sandbox image /
# certs.d). karr #9 stopped NEW clobbering, but on a host already clobbered by
# 0.002 the generated config.toml still shows an nvidia runtime, so #9's
# "already-wired" check no-ops and leaves the clobber in place. #13 heals it by
# removing that stale template so the distro regenerates its native config.
#
# _is_rke2_clobber_tmpl($content) is the pure decision (regex/string only, no
# run/file) so it is unit-testable offline, like _containerd_nvidia_action /
# _nvidia_driver_present / _cdi_managed_source_present. Removing a file on a
# live remote root shell is the top risk, so the CRITICAL claim these tests
# guard is the false-positive boundary: the predicate matches ONLY the exact
# bare clobber, and NEVER the #9 base-extending config.toml.tmpl, the v3
# drop-in, or a user's own custom tmpl.
#
# WHAT THIS TEST DOES NOT COVER -- and it is NOT hardware-verified. The live
# heal is NOT exercised here: that configure_containerd actually removes the
# stale template, that RKE2/K3s then regenerate a healthy native config.toml on
# restart, and that the node comes back with SystemdCgroup / pinned sandbox /
# certs.d restored plus a working nvidia runtime. It could not be: no clobbered
# node was available and the containerd step never ran live -- the otho-lab
# pipeline died at the driver step (karr #7). A maintainer MUST reproduce a node
# clobbered by old 0.002 against modern RKE2 (containerd 2.x / config v3), run
# configure_containerd, restart RKE2 (or reboot), and confirm the regenerated
# config.toml carries SystemdCgroup, the pinned sandbox image and the certs.d
# config_path AND the nvidia runtime. A green prove is NOT evidence any of that
# works. See the t/10-detect.t header for the wider "what prove cannot see".
#
# CLAIM asserted by these tests:
#   * the EXACT bare 0.002 clobber (imports= + version=2, no base directive)
#     => 1 (remove it)
#   * the #9 base-extending config.toml.tmpl                       => 0 (keep)
#   * the v3 drop-in the module emits today                        => 0 (keep)
#   * a user's custom tmpl / anything carrying real base config    => 0 (keep)
#   * empty / undef / imports-only / version-only / version=3      => 0 (keep)
# -----------------------------------------------------------------------------

use Rex::GPU::NVIDIA;

sub clobber { Rex::GPU::NVIDIA->_is_rke2_clobber_tmpl(@_) }

# The EXACT content rex-gpu 0.002 wrote to config.toml.tmpl.
my $bare_clobber = qq{imports = ["/etc/containerd/conf.d/*.toml"]\nversion = 2\n};

subtest 'the exact 0.002 clobber => remove (1)' => sub {
  is(clobber($bare_clobber), 1,
    'bare imports= + version=2 (the 0.002 full-config clobber) => 1');

  # Order-independent: version line first.
  is(clobber(qq{version = 2\nimports = ["/etc/containerd/conf.d/*.toml"]\n}), 1,
    'version=2 then imports= (same artifact, reordered) => 1');

  # Blank lines and # comments are ignored.
  is(clobber(qq{# rke2\n\nimports = ["/etc/containerd/conf.d/*.toml"]\n\nversion = 2\n}), 1,
    'blank lines + comments around the two lines => still 1');

  # version=2 with no spaces around '='.
  is(clobber(qq{imports=["/etc/containerd/conf.d/*.toml"]\nversion=2\n}), 1,
    'no-space imports=/version=2 => 1');
};

subtest 'the #9 base-extending tmpl => keep (0) -- the critical guard' => sub {
  my $safe = Rex::GPU::NVIDIA->_nvidia_containerd_tmpl_v2();
  is(clobber($safe), 0,
    'the exact base-extending config.toml.tmpl the module emits today => 0');
  # It is the `{{ template "base" . }}` directive that makes it safe.
  like($safe, qr/\{\{\s*template "base" \.\s*\}\}/,
    'sanity: that tmpl does carry the base-render directive');

  # A base-extending tmpl that ALSO happens to import conf.d must still be kept.
  is(clobber(qq{{{ template "base" . }}\nimports = ["/etc/containerd/conf.d/*.toml"]\nversion = 2\n}), 0,
    'base directive present => 0 even with imports= + version=2 lines');
};

subtest 'the v3 drop-in the module emits today => keep (0)' => sub {
  is(clobber(Rex::GPU::NVIDIA->_nvidia_containerd_dropin_v3()), 0,
    'v3 drop-in (version=3 + plugins) is not the clobber => 0');
};

subtest "a user's own / real-config tmpl => keep (0)" => sub {
  # Any [plugins...] section means it carries real config, not the bare clobber.
  my $with_plugins = $bare_clobber
    . qq{[plugins."io.containerd.grpc.v1.cri"]\n  sandbox_image = "x"\n};
  is(clobber($with_plugins), 0,
    'imports= + version=2 PLUS a real [plugins...] section => 0 (has base config)');

  # An admin's hand-written full v2 config with runtimes.
  my $custom = <<'TOML';
version = 2

[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.example/pause:3.9"
  [plugins."io.containerd.grpc.v1.cri".containerd]
    default_runtime_name = "runc"
TOML
  is(clobber($custom), 0, "a user's custom config.toml.tmpl => 0");
};

subtest 'degenerate / partial inputs => keep (0)' => sub {
  is(clobber(undef), 0, 'undef => 0');
  is(clobber(''),    0, 'empty string => 0');
  is(clobber("\n\n# only comments\n"), 0, 'no substantive lines => 0');
  is(clobber(qq{imports = ["/etc/containerd/conf.d/*.toml"]\n}), 0,
    'imports= only, no version => 0');
  is(clobber(qq{version = 2\n}), 0, 'version=2 only, no imports => 0');
  is(clobber(qq{imports = ["/etc/containerd/conf.d/*.toml"]\nversion = 3\n}), 0,
    'imports= + version=3 (not v2) => 0');
};

done_testing;
