#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# gpu_setup's AMD dispatch (karr k1), with detection and every step replaced
# by recorders (the shape of t/05-gpu-setup.t): which AMD GPU is passed on,
# which is skipped and why, which calls run, in which order.
#
# CLAIMS:
#   * a GPU with compute undef (no hardware row), compute 0 (known, not
#     ROCm-capable) or integrated 1 without amd_integrated => 1 gets NO
#     install_driver and NO verify_amd, and exactly one warning naming the GPU
#     and the reason ("no hardware row for it, compute unknown" / "not
#     ROCm-capable" / "integrated GPU (APU); pass amd_integrated => 1 ...");
#   * an integrated GPU with amd_integrated => 1, and a discrete GPU with
#     compute 1, get install_driver(gpus => [the GPUs], reboot => 0|1) and
#     then verify_amd(gpus => [the same]) -- in that order, and only the
#     passable GPUs when the host has several;
#   * the AMD steps never run the NVIDIA toolkit, CDI or containerd steps,
#     whatever containerd_config says; a host with NVIDIA and AMD runs the
#     NVIDIA pipeline first;
#   * amd => 'Class' and `set gpu_amd_class` make both steps class methods of
#     that subclass (option beats the set); a class that cannot be loaded or
#     is not a Rex::GPU::AMD dies before detection; the default class is
#     Rex::GPU::AMD; Rex::GPU->can('amd_class') (the feature flag Rex::Rancher
#     and kubernetes-ocp test for);
#   * a die of install_driver ends gpu_setup, and verify_amd is not reached;
#   * the detection result is returned as is.
#
# NOT covered: what install_driver / verify_amd do (t/16, t/17 -- here they
# are recorders), detection (t/14), and anything a real host does.
# -----------------------------------------------------------------------------

use Rex::Config;
use Rex::GPU;
use Rex::GPU::AMD;

{
  package Test::AMDDispatch::Class;
  use parent -norequire, 'Rex::GPU::AMD';
  our @CALLS;
  sub install_driver { my ( $class, %a ) = @_; push @CALLS, [ install_driver => $class, %a ]; return 'present' }
  sub verify_amd     { my ( $class, %a ) = @_; push @CALLS, [ verify_amd => $class, %a ]; return { ok => 1, gpus => [] } }
}
{
  package Test::AMDDispatch::NotAMD;
  sub install_driver { die "not reached\n" }
}

my @STEPS = qw( install_driver install_container_toolkit generate_cdi_specs configure_containerd verify_nvidia );

sub setup_with {
  my ( $detected, @opts ) = @_;
  my ( @calls, @logs, $detect_calls );
  my $rec = sub { my ( $s ) = @_; sub { push @calls, [ $s, @_ ]; 1 } };
  no warnings 'redefine';
  local *Rex::GPU::gpu_detect = sub { $detect_calls++; return $detected };
  local *Rex::GPU::NVIDIA::install_driver            = $rec->('nvidia:install_driver');
  local *Rex::GPU::NVIDIA::install_container_toolkit = $rec->('nvidia:install_container_toolkit');
  local *Rex::GPU::NVIDIA::generate_cdi_specs        = $rec->('nvidia:generate_cdi_specs');
  local *Rex::GPU::NVIDIA::configure_containerd      = $rec->('nvidia:configure_containerd');
  local *Rex::GPU::NVIDIA::verify_nvidia             = $rec->('nvidia:verify_nvidia');
  local *Rex::GPU::AMD::install_driver               = $rec->('amd:install_driver');
  local *Rex::GPU::AMD::verify_amd                   = $rec->('amd:verify_amd');
  local *Rex::Logger::info = sub { push @logs, [ $_[1] // 'info', $_[0] ] };
  local *Rex::get_current_connection = sub { return };
  @Test::AMDDispatch::Class::CALLS = ();
  my $error;
  my $ret = eval { Rex::GPU::gpu_setup(@opts) } // do { $error = $@; undef };
  return { ret => $ret, error => $error, calls => \@calls, logs => \@logs, detect_calls => $detect_calls };
}

sub steps { my ( $r ) = @_; [ map { $_->[0] } @{ $r->{calls} } ] }
sub warns { my ( $r ) = @_; [ map { $_->[1] } grep { $_->[0] eq 'warn' } @{ $r->{logs} } ] }
sub call  { my ( $r, $name ) = @_; my ( $c ) = grep { $_->[0] eq $name } @{ $r->{calls} }; return $c ? { @{$c}[1 .. $#$c] } : undef }

sub hosts { my ( %h ) = @_; return { nvidia => [], amd => [], nvswitch => [], %h } }
sub amd_gpu {
  my ( $name, %h ) = @_;
  return { name => $name, vendor => 'amd', pci_class => '0300', slot => '0000:0a:00.0', device_id => '744c',
           gfx_target => 'gfx1100', compute => 1, integrated => 0, %h };
}

my $DISCRETE = amd_gpu('Navi 31 [Radeon RX 7900 XTX]');
my $APU      = amd_gpu('AMD GPU [1002:1586]', pci_class => '0380', slot => '0000:95:00.0', device_id => '1586',
                       gfx_target => 'gfx1151', integrated => 1);
my $UNKNOWN  = amd_gpu('AMD GPU [1002:1902]', device_id => '1902', gfx_target => undef, compute => undef, integrated => undef);
my $LEGACY   = amd_gpu('Vega 20 [Radeon VII]', device_id => '66af', gfx_target => 'gfx906', compute => 0);
my $ADA      = { name => 'NVIDIA RTX 4000 SFF Ada Generation', device_id => '27b0', compute => 1 };

#### skips

subtest 'skipped AMD GPUs: no install, one warning with the reason' => sub {
  my %why = (
    unknown    => [ $UNKNOWN,  qr/\AAMD GPU detected: AMD GPU \[1002:1902\] -- no driver installed: no hardware row for it, compute unknown\z/ ],
    legacy     => [ $LEGACY,   qr/\AAMD GPU detected: Vega 20 \[Radeon VII\] -- no driver installed: not ROCm-capable\z/ ],
    integrated => [ $APU,      qr/\AAMD GPU detected: AMD GPU \[1002:1586\] -- no driver installed: integrated GPU \(APU\); pass amd_integrated => 1 to install for it\z/ ],
  );
  for my $k (sort keys %why) {
    my ( $gpu, $re ) = @{ $why{$k} };
    my $d = hosts(amd => [ $gpu ]);
    my $r = setup_with($d, reboot => 1);
    is($r->{error}, undef, "$k: no die");
    is_deeply(steps($r), [], "$k: no install_driver, no verify_amd, no other step");
    is(scalar @{ warns($r) }, 1, "$k: exactly one warning");
    like(warns($r)->[0], $re, "$k: ... naming the GPU and the reason");
    is($r->{ret}, $d, "$k: returns the detection result");
  }
};

subtest 'compute 0 beats integrated: a not-capable APU says "not ROCm-capable"' => sub {
  my $r = setup_with(hosts(amd => [ amd_gpu('Raphael', device_id => '164e', gfx_target => 'gfx1036', compute => 0, integrated => 1) ]),
    amd_integrated => 1);
  is_deeply(steps($r), [], 'nothing installed, also with amd_integrated => 1');
  like(warns($r)->[0], qr/-- no driver installed: not ROCm-capable\z/, '... the reason is compute 0');
};

#### installs

subtest 'discrete compute 1: install_driver then verify_amd' => sub {
  my $r = setup_with(hosts(amd => [ $DISCRETE ]));
  is_deeply(steps($r), [ 'amd:install_driver', 'amd:verify_amd' ], 'install, then verify, nothing else');
  is_deeply(call($r, 'amd:install_driver'), { gpus => [ $DISCRETE ], reboot => 0 }, 'install_driver(gpus => [it], reboot => 0)');
  is_deeply(call($r, 'amd:verify_amd'), { gpus => [ $DISCRETE ] }, 'verify_amd(gpus => [it])');
  is_deeply(warns($r), [], 'no warning');
  ok(( grep { $_->[1] eq 'ROCm-capable AMD GPU: Navi 31 [Radeon RX 7900 XTX]' } @{ $r->{logs} } ), 'logged as ROCm-capable');
};

subtest 'reboot is passed as 1/0' => sub {
  is(call(setup_with(hosts(amd => [ $DISCRETE ]), reboot => 1), 'amd:install_driver')->{reboot}, 1, 'reboot => 1');
  is(call(setup_with(hosts(amd => [ $DISCRETE ]), reboot => 'yes'), 'amd:install_driver')->{reboot}, 1, 'reboot => "yes"');
  is(call(setup_with(hosts(amd => [ $DISCRETE ]), reboot => 0), 'amd:install_driver')->{reboot}, 0, 'reboot => 0');
};

subtest 'integrated GPU with amd_integrated => 1' => sub {
  my $r = setup_with(hosts(amd => [ $APU ]), amd_integrated => 1);
  is_deeply(steps($r), [ 'amd:install_driver', 'amd:verify_amd' ], 'install_driver and verify_amd');
  is_deeply(call($r, 'amd:install_driver'), { gpus => [ $APU ], reboot => 0 }, 'handed the APU');
  is_deeply(call($r, 'amd:verify_amd'), { gpus => [ $APU ] }, '... verify_amd too');
  is_deeply(warns($r), [], 'no warning');

  my $off = setup_with(hosts(amd => [ $APU ]), amd_integrated => 0);
  is_deeply(steps($off), [], 'amd_integrated => 0 is the default: skipped');
};

subtest 'several AMD GPUs: only the passable ones are handed on' => sub {
  my $r = setup_with(hosts(amd => [ $UNKNOWN, $DISCRETE, $LEGACY, $APU ]));
  is_deeply(call($r, 'amd:install_driver')->{gpus}, [ $DISCRETE ], 'install_driver: the discrete one only (the APU needs amd_integrated)');
  is_deeply(call($r, 'amd:verify_amd')->{gpus}, [ $DISCRETE ], 'verify_amd: the same');
  is(scalar @{ warns($r) }, 3, 'three warnings, one per skipped GPU');

  $r = setup_with(hosts(amd => [ $UNKNOWN, $DISCRETE, $LEGACY, $APU ]), amd_integrated => 1);
  is_deeply(call($r, 'amd:install_driver')->{gpus}, [ $DISCRETE, $APU ], 'with amd_integrated => 1: discrete and APU, in host order');
  is(scalar @{ warns($r) }, 2, '... two warnings');
};

subtest 'AMD never runs the NVIDIA toolkit / CDI / containerd steps' => sub {
  for my $cc (qw( rke2 k3s containerd none )) {
    my $r = setup_with(hosts(amd => [ $DISCRETE ]), containerd_config => $cc);
    is_deeply(steps($r), [ 'amd:install_driver', 'amd:verify_amd' ], "containerd_config => $cc: AMD steps only");
  }
  my $bad = setup_with(hosts(amd => [ $DISCRETE ]), containerd_config => 'bogus');
  like($bad->{error}, qr/Unknown containerd runtime: bogus/, 'a bad containerd_config still dies (before detection)');
  is($bad->{detect_calls}, undef, '... so before detection');
};

subtest 'NVIDIA next to AMD: the NVIDIA pipeline first, then AMD' => sub {
  my $r = setup_with(hosts(nvidia => [ $ADA ], amd => [ $DISCRETE ]));
  is_deeply(steps($r), [ map({ 'nvidia:'.$_ } @STEPS), 'amd:install_driver', 'amd:verify_amd' ], 'NVIDIA steps in order, then the AMD ones');
  is_deeply(warns($r), [], 'no warning');
};

#### classes

subtest 'amd_class and the feature flag' => sub {
  ok(Rex::GPU->can('amd_class'), 'Rex::GPU->can(amd_class)');
  is(Rex::GPU->amd_class, 'Rex::GPU::AMD', 'default: Rex::GPU::AMD');
  is(Rex::GPU->amd_class('Test::AMDDispatch::Class'), 'Test::AMDDispatch::Class', 'the option names the class');
  is(Rex::GPU->amd_class(undef), 'Rex::GPU::AMD', 'undef option: the default');
  is(Rex::GPU->amd_class(''), 'Rex::GPU::AMD', 'empty option: the default');
};

subtest 'amd => Class: both steps are class methods of that class' => sub {
  my $r = setup_with(hosts(amd => [ $DISCRETE ]), reboot => 1, amd => 'Test::AMDDispatch::Class');
  is_deeply(steps($r), [], 'the built-in Rex::GPU::AMD functions are not called');
  is_deeply([ map { [ @{$_}[0, 1] ] } @Test::AMDDispatch::Class::CALLS ],
    [ [ install_driver => 'Test::AMDDispatch::Class' ], [ verify_amd => 'Test::AMDDispatch::Class' ] ],
    'install_driver then verify_amd, invocant = the class');
  my %install = @{ $Test::AMDDispatch::Class::CALLS[0] }[2 .. 5];
  is_deeply(\%install, { gpus => [ $DISCRETE ], reboot => 1 }, 'the same arguments as for the built-in');
};

subtest 'set gpu_amd_class works; the option beats it' => sub {
  Rex::Config->set(gpu_amd_class => 'Test::AMDDispatch::Class');
  my $r = eval { setup_with(hosts(amd => [ $DISCRETE ])) };
  my $err = $@;
  Rex::Config->set(gpu_amd_class => undef);
  die $err if $err;
  is(scalar @Test::AMDDispatch::Class::CALLS, 2, 'set gpu_amd_class: the class got both calls');

  Rex::Config->set(gpu_amd_class => 'Test::AMDDispatch::Class');
  $r = eval { setup_with(hosts(amd => [ $DISCRETE ]), amd => 'Rex::GPU::AMD') };
  $err = $@;
  Rex::Config->set(gpu_amd_class => undef);
  die $err if $err;
  is(scalar @Test::AMDDispatch::Class::CALLS, 0, 'amd => Rex::GPU::AMD beats the set: the class got nothing');
  is_deeply(steps($r), [ 'amd:install_driver', 'amd:verify_amd' ], '... the built-in functions ran');
};

subtest 'a bad AMD class dies before detection' => sub {
  for my $bad ( [ 'No::Such::AMD::Class' => qr/No::Such::AMD::Class/ ],
                [ 'Test::AMDDispatch::NotAMD' => qr/Rex::GPU::AMD/ ],
                [ 'not a package' => qr/not a package|class name/i ] ) {
    my ( $class, $re ) = @$bad;
    my $r = setup_with(hosts(amd => [ $DISCRETE ]), amd => $class);
    like($r->{error}, $re, "'$class': dies");
    is($r->{detect_calls}, undef, '... before detection');
    is_deeply(steps($r), [], '... and before any step');
  }
};

#### failure

subtest 'install_driver dying ends gpu_setup; verify_amd is not reached' => sub {
  my $detected = hosts(amd => [ $DISCRETE ]);
  my ( @calls );
  no warnings 'redefine';
  local *Rex::GPU::gpu_detect = sub { $detected };
  local *Rex::GPU::AMD::install_driver = sub { push @calls, 'install_driver'; die "install_driver: Secure Boot is enabled. Nothing was changed on the host\n" };
  local *Rex::GPU::AMD::verify_amd = sub { push @calls, 'verify_amd'; { ok => 1, gpus => [] } };
  local *Rex::Logger::info = sub { };
  local *Rex::get_current_connection = sub { return };
  eval { Rex::GPU::gpu_setup() };
  like($@, qr/Secure Boot is enabled/, 'the die reaches the caller');
  is_deeply(\@calls, [ 'install_driver' ], '... verify_amd never ran');
};

done_testing;
