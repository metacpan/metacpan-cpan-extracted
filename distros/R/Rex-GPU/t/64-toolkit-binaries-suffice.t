use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# install_container_toolkit(binaries_suffice => 1) (karr #74, escalated from
# kubernetes-ocp#196): counts the toolkit as present from `command -v` and
# `nvidia-ctk --version` alone, without asking the package manager, for hosts
# whose binaries did not come from a package (DGX Spark) and for callers who
# leave the containerd wiring to RKE2/K3s (configure_containerd is never
# called by them, so the packaged nvidia-container-runtime is not needed).
#
# CLAIMS:
#   * all three probes good, on debian-12/ubuntu-24.04/rocky-9/leap-16.0: the
#     transcript is exactly the two `command -v` lines and `nvidia-ctk
#     --version`, nothing else -- the check runs before the OS family is
#     decided, so the same three lines come out of every OS; the last log is
#     the "already present" info line with both paths and the first version
#     line; mutating_lines is empty (the harness's read-only list was
#     extended for this, in Test::RexGPU::Golden.pm, in its own step);
#   * nvidia-container-runtime missing (exit 1, or exit 0 with empty output):
#     one `command -v` line, an info log, then the OS's default transcript,
#     byte for byte;
#   * nvidia-ctk missing: two `command -v` lines, an info log, then the
#     default transcript;
#   * `nvidia-ctk --version` fails: all three probes, a WARN log, then the
#     default transcript;
#   * binaries_suffice => 0, and no option at all, reproduce the existing,
#     untouched t/golden/toolkit/<os>.txt exactly -- the default is unchanged;
#   * an unknown option, and an odd-length option list, die with the exact
#     messages before any host command, whether or not binaries_suffice is
#     also given;
#   * Rex::GPU::NVIDIA->install_container_toolkit(binaries_suffice => 1) (the
#     class-method form) emits the same transcript as the bare function call;
#     set gpu_nvidia_class routes a bare function call's binaries_suffice
#     option to the configured subclass; a subclass's own
#     _toolkit_binaries_present override runs instead of the built-in probes
#     and its return value is what install_container_toolkit acts on;
#   * an OS with no install path (Gentoo): with the option and both binaries
#     present, returns after only the three probes -- no "Unsupported OS" die;
#     without the option, the same host still dies exactly as
#     t/63-toolkit-unknown-os.t already pins;
#   * gpu_setup's own call to install_container_toolkit passes no arguments:
#     with the built-in class it is a bare function call and @_ is completely
#     empty; routed to a configured subclass it is a method call and @_ holds
#     only the invocant -- binaries_suffice never sneaks in either way.
#
# NOT covered -- a green prove is NOT evidence that this works on a host:
#   * that `command -v` finds the same thing over Rex::LibSSH as over plain
#     SSH/OpenSSH, or on a real DGX Spark image;
#   * that a DGX Spark (or any other vendor image) actually looks like the
#     canned `command -v`/`--version` output here -- hand-written to match
#     the shape of t/97-golden-toolkit.t's existing $CTK_VERSION fixture, not
#     captured from a real device;
#   * what RKE2/K3s do with a runtime they find on PATH this way, or whether
#     skipping configure_containerd (a caller decision, not this option's)
#     leaves a working CRI config.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile mutating_lines );
use Rex::GPU;
use Rex::GPU::NVIDIA;

# Rex::Config->set(...) is shared by every host of a Rexfile; reset it after
# each case even if the case dies (as t/99-class-dispatch.t's with_config).
sub with_config {
  my ( $key, $value, $code ) = @_;
  Rex::Config->set($key => $value);
  my $ok  = eval { $code->(); 1 };
  my $err = $@;
  Rex::Config->set($key => undef);
  die $err unless $ok;
}

# Reused verbatim from t/97-golden-toolkit.t's $CTK_VERSION fixture -- not a
# capture, a hand-written stand-in already established there.
my $CTK_VERSION = "NVIDIA Container Toolkit CLI version 1.17.8\ncommit: f202b80a9b9d0db00d9b1d73c0128c8962c55f4d";
my $CTK_FIRST_LINE = "NVIDIA Container Toolkit CLI version 1.17.8";

my @BOTH_PRESENT = (
  [ 'command -v nvidia-container-runtime 2>/dev/null' => '/usr/bin/nvidia-container-runtime', 0 ],
  [ 'command -v nvidia-ctk 2>/dev/null'                => '/usr/bin/nvidia-ctk', 0 ],
  [ 'nvidia-ctk --version 2>&1'                        => $CTK_VERSION, 0 ]
);

my @THREE_PROBE_LINES = (
  'run: command -v nvidia-container-runtime 2>/dev/null',
  'run: command -v nvidia-ctk 2>/dev/null',
  'run: nvidia-ctk --version 2>&1'
);

sub toolkit_binsuf {
  my ( $host, %opt ) = @_;
  return record_host(
    host => $host,
    code => sub { Rex::GPU::NVIDIA::install_container_toolkit(binaries_suffice => ($opt{value} // 1)) }
  );
}

sub toolkit_default {
  my ( $host ) = @_;
  return record_host(host => $host, code => sub { Rex::GPU::NVIDIA::install_container_toolkit() });
}

#### 1. all three probes good: same three lines, on every OS #################

for my $os (qw( debian-12 ubuntu-24.04 rocky-9 leap-16.0 )) {
  my $rec = toolkit_binsuf(host_profile($os, responses => [ @BOTH_PRESENT ]));
  # One golden for all four OSes: the transcript does not depend on the OS
  # family -- the check runs before it is even read.
  golden_is($rec, 'toolkit/binaries-suffice--all-present', "binaries_suffice, all present: $os");
  is_deeply($rec->{lines}, \@THREE_PROBE_LINES, "$os: exactly the three probes, nothing else");
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], "$os: nothing on the host is changed");
  is($rec->{logs}[-1][1],
    'NVIDIA Container Toolkit already present (binaries_suffice: /usr/bin/nvidia-container-runtime, '
    .'/usr/bin/nvidia-ctk, '.$CTK_FIRST_LINE.') — skipping repository setup and install; '
    .'the package manager was not asked',
    "$os: the last log has both paths and the first version line");
  is($rec->{logs}[-1][0], 'info', "$os: logged at info, not warn");
}

#### 2. nvidia-container-runtime missing: one command -v line, then default ##

for my $case ([ 'exit 1' => '', 1 ], [ 'exit 0, empty output' => '', 0 ]) {
  my ( $label, $out, $exit ) = @$case;
  my $rec = toolkit_binsuf(host_profile('debian-12', responses => [
    [ 'command -v nvidia-container-runtime 2>/dev/null' => $out, $exit ]
  ]));
  my $default = toolkit_default(host_profile('debian-12'));
  is($rec->{error}, $default->{error}, "runtime missing ($label): same result as the default install");
  is_deeply($rec->{lines}, [ $THREE_PROBE_LINES[0], @{ $default->{lines} } ],
    "runtime missing ($label): one command -v line, then byte for byte the default transcript");
  is($rec->{logs}[0][1],
    'binaries_suffice: nvidia-container-runtime not found on the PATH — checking for the '
    .'nvidia-container-toolkit package as without the option',
    "runtime missing ($label): the info log");
  is($rec->{logs}[0][0], 'info', "runtime missing ($label): logged at info, not warn");
}

#### 3. nvidia-ctk missing: two command -v lines, then default ###############

{
  my $rec = toolkit_binsuf(host_profile('debian-12', responses => [
    [ 'command -v nvidia-container-runtime 2>/dev/null' => '/usr/bin/nvidia-container-runtime', 0 ],
    [ 'command -v nvidia-ctk 2>/dev/null'                => '', 1 ]
  ]));
  my $default = toolkit_default(host_profile('debian-12'));
  is($rec->{error}, $default->{error}, 'ctk missing: same result as the default install');
  is_deeply($rec->{lines}, [ @THREE_PROBE_LINES[0,1], @{ $default->{lines} } ],
    'ctk missing: two command -v lines, then byte for byte the default transcript');
  is($rec->{logs}[0][1],
    'binaries_suffice: nvidia-ctk not found on the PATH — checking for the nvidia-container-toolkit '
    .'package as without the option',
    'ctk missing: the info log');
}

#### 4. nvidia-ctk --version fails: all three probes, a WARN, then default ###

{
  my $rec = toolkit_binsuf(host_profile('debian-12', responses => [
    [ 'command -v nvidia-container-runtime 2>/dev/null' => '/usr/bin/nvidia-container-runtime', 0 ],
    [ 'command -v nvidia-ctk 2>/dev/null'                => '/usr/bin/nvidia-ctk', 0 ],
    [ 'nvidia-ctk --version 2>&1'                        => 'error while loading shared libraries', 127 ]
  ]));
  my $default = toolkit_default(host_profile('debian-12'));
  is($rec->{error}, $default->{error}, '--version fails: same result as the default install');
  is_deeply($rec->{lines}, [ @THREE_PROBE_LINES, @{ $default->{lines} } ],
    '--version fails: all three probes, then byte for byte the default transcript');
  is($rec->{logs}[0][1],
    'binaries_suffice: /usr/bin/nvidia-ctk does not run (nvidia-ctk --version failed) — checking for the '
    .'nvidia-container-toolkit package as without the option',
    '--version fails: the log message names the path');
  is($rec->{logs}[0][0], 'warn', '--version fails: logged at warn, unlike the two "missing" cases');
}

#### 5. default unchanged: reproduces the existing golden exactly ############

for my $os (qw( debian-12 ubuntu-24.04 rocky-9 leap-16.0 )) {
  golden_is(toolkit_default(host_profile($os)), "toolkit/$os", "no option, $os: still the existing golden");
  golden_is(toolkit_binsuf(host_profile($os), value => 0), "toolkit/$os", "binaries_suffice => 0, $os: same golden");
}

#### 6. unknown option / odd-length list: die before any host command #######

subtest 'bad options die before any host command' => sub {
  for my $case (
    [ [ binary_suffice => 1 ],                'install_container_toolkit: unknown option binary_suffice (valid: binaries_suffice)' ],
    [ [ 'binaries_suffice' ],                 'install_container_toolkit: options are key => value pairs' ],
    [ [ binaries_suffice => 1, extra => 1 ],  'install_container_toolkit: unknown option extra (valid: binaries_suffice)' ]
  ) {
    my ( $args, $want ) = @$case;
    my $rec = record_host(host => host_profile('debian-12'),
      code => sub { Rex::GPU::NVIDIA::install_container_toolkit(@$args) });
    is($rec->{error}, $want, "(@$args): dies with the exact message");
    is_deeply($rec->{lines}, [], "(@$args): no host command");
  }
};

#### 7. class-method form, a configured subclass, and its override ##########

subtest 'Class->method(...) form: same transcript as the bare function call' => sub {
  my $fn = toolkit_binsuf(host_profile('debian-12', responses => [ @BOTH_PRESENT ]));
  my $cm = record_host(host => host_profile('debian-12', responses => [ @BOTH_PRESENT ]),
    code => sub { Rex::GPU::NVIDIA->install_container_toolkit(binaries_suffice => 1) });
  is($cm->{error}, $fn->{error}, 'same result (lives)');
  is_deeply($cm->{lines}, $fn->{lines}, 'Rex::GPU::NVIDIA->install_container_toolkit(...) matches the bare call');
};

{
  package Local::K74::OverrideBinaries;
  use parent -norequire, 'Rex::GPU::NVIDIA';
  our @CALLED;
  # Replaces the built-in probes entirely: a passing test proves this ran,
  # not that it ran the real thing afterwards.
  sub _toolkit_binaries_present {
    my ( $class ) = @_;
    push @CALLED, $class;
    return 1;
  }
}

subtest 'set gpu_nvidia_class routes a bare call to the subclass, whose override runs' => sub {
  @Local::K74::OverrideBinaries::CALLED = ();
  with_config(gpu_nvidia_class => 'Local::K74::OverrideBinaries', sub {
    my $rec = record_host(host => host_profile('debian-12'),
      code => sub { Rex::GPU::NVIDIA::install_container_toolkit(binaries_suffice => 1) });
    is($rec->{error}, undef, 'bare function call, subclass configured via set: lives');
    is_deeply($rec->{lines}, [], 'no host command at all -- the override answered without touching the host');
    is_deeply(\@Local::K74::OverrideBinaries::CALLED, [ 'Local::K74::OverrideBinaries' ],
      'the configured subclass, not the base class, ran _toolkit_binaries_present');
  });
};

{
  package Local::K74::NeverSuffices;
  use parent -norequire, 'Rex::GPU::NVIDIA';
  our @CALLED;
  sub _toolkit_binaries_present { push @CALLED, $_[0]; return 0 }
}

{
  package Local::K74::CaptureToolkitCall;
  use parent -norequire, 'Rex::GPU::NVIDIA';
  our @CALLS;
  sub install_container_toolkit { push @CALLS, [ @_ ]; return }
}

subtest 'a false override: install_container_toolkit goes on as without the option' => sub {
  @Local::K74::NeverSuffices::CALLED = ();
  my $rec = record_host(host => host_profile('debian-12'),
    code => sub { Local::K74::NeverSuffices->install_container_toolkit(binaries_suffice => 1) });
  my $default = record_host(host => host_profile('debian-12'),
    code => sub { Rex::GPU::NVIDIA::install_container_toolkit() });
  is($rec->{error}, $default->{error}, 'same result as the default install');
  is_deeply($rec->{lines}, $default->{lines}, 'same transcript as the default install');
  is_deeply(\@Local::K74::NeverSuffices::CALLED, [ 'Local::K74::NeverSuffices' ], 'the override ran, and was believed');
};

#### 8. an OS with no install path (Gentoo) ##################################

subtest 'Gentoo: with the option and both binaries, returns; without, dies as t/63 pins' => sub {
  my $rec = record_host(host => host_profile('debian-12', os => 'Gentoo', responses => [ @BOTH_PRESENT ]),
    code => sub { Rex::GPU::NVIDIA::install_container_toolkit(binaries_suffice => 1) });
  is($rec->{error}, undef, 'Gentoo + binaries_suffice + both binaries: lives');
  is_deeply($rec->{lines}, \@THREE_PROBE_LINES, '... returns after only the three probes, no "Unsupported OS"');

  my $rec2 = record_host(host => host_profile('debian-12', os => 'Gentoo'),
    code => sub { Rex::GPU::NVIDIA::install_container_toolkit() });
  is($rec2->{error}, 'Unsupported OS for NVIDIA Container Toolkit: Gentoo',
    '... same host, without the option: dies naming the OS (t/63-toolkit-unknown-os.t pins this generally)');
  is_deeply($rec2->{lines}, [], '... no host command');
};

#### 9. gpu_setup passes install_container_toolkit no arguments ##############

subtest "gpu_setup's own call: no arguments, whichever class runs it" => sub {
  my $ada = { name => 'NVIDIA RTX 4000 SFF Ada Generation', device_id => '27b0', compute => 1 };

  # Built-in class (no custom nvidia class): _step calls it as a bare
  # function -- @_ is not just invocant-less, it is completely empty.
  {
    my @raw = ( 'unset' );
    no warnings 'redefine';
    local *Rex::GPU::NVIDIA::install_container_toolkit = sub { @raw = @_ };
    local *Rex::GPU::NVIDIA::install_driver            = sub { };
    local *Rex::GPU::NVIDIA::generate_cdi_specs        = sub { };
    local *Rex::GPU::NVIDIA::configure_containerd      = sub { };
    local *Rex::GPU::NVIDIA::verify_nvidia             = sub { };
    local *Rex::GPU::_check_connection                 = sub { };
    local *Rex::GPU::Detect::detect                    = sub { { nvidia => [ $ada ], amd => [], nvswitch => [] } };
    local *Rex::Logger::info                           = sub { };
    Rex::GPU::gpu_setup();
    is_deeply(\@raw, [], 'built-in class: install_container_toolkit is called with zero arguments');
  }

  # A configured subclass (nvidia => ...): _step calls it as a method --
  # @_ holds only the invocant.
  @Local::K74::CaptureToolkitCall::CALLS = ();
  no warnings 'redefine';
  local *Rex::GPU::NVIDIA::install_driver       = sub { };
  local *Rex::GPU::NVIDIA::generate_cdi_specs   = sub { };
  local *Rex::GPU::NVIDIA::configure_containerd = sub { };
  local *Rex::GPU::NVIDIA::verify_nvidia        = sub { };
  local *Rex::GPU::_check_connection            = sub { };
  local *Rex::GPU::Detect::detect               = sub { { nvidia => [ $ada ], amd => [], nvswitch => [] } };
  local *Rex::Logger::info                      = sub { };
  Rex::GPU::gpu_setup(nvidia => 'Local::K74::CaptureToolkitCall', containerd_config => 'none');
  is_deeply(\@Local::K74::CaptureToolkitCall::CALLS, [ [ 'Local::K74::CaptureToolkitCall' ] ],
    'configured subclass: exactly one call, @_ holding only the invocant -- nothing else sneaked in');
};

done_testing;
