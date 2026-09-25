use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# gpu_setup's own decisions (karr #63), with detection and every pipeline step
# replaced by recorders: which steps run, in which order, with which options.
# What each step emits is t/31, t/41, t/61, t/96, t/97's job.
#
# CLAIMS:
#   * no GPU, AMD only, or NVIDIA without a compute GPU => no pipeline step
#     runs; AMD only => exactly one warning (driver support not implemented),
#     no GPU / no compute GPU => none from gpu_setup;
#   * a compute GPU => install_driver, install_container_toolkit,
#     generate_cdi_specs, configure_containerd, verify_nvidia, in that order;
#     only the compute GPUs are passed;
#   * reboot: gpu_setup passes reboot => 1 for a true `reboot`, 0 otherwise
#     (the default);
#   * containerd_config defaults to rke2; 'none' skips configure_containerd;
#   * an unknown containerd_config dies naming the valid values before
#     detection, so before install_driver -- with or without a GPU (karr #66);
#   * NVIDIA next to AMD => the pipeline plus the one AMD warning;
#   * the detection result is returned as is.
#
# NOT covered: detection itself (t/10), the steps' commands, and anything a
# real host does. _check_connection is t/06's; here the connection is absent.
# -----------------------------------------------------------------------------

use Rex::GPU;

my @STEPS = qw( install_driver install_container_toolkit generate_cdi_specs configure_containerd verify_nvidia );

sub setup_with {
  my ( $detected, @opts ) = @_;
  my ( @calls, @logs, $detect_calls );
  my $rec = sub { my ( $s ) = @_; sub { push @calls, [ $s, @_ ]; 1 } };
  no warnings 'redefine';
  local *Rex::GPU::gpu_detect = sub { $detect_calls++; return $detected };
  # one `local` per step: a `local ... for LIST` would not outlive its loop
  local *Rex::GPU::NVIDIA::install_driver            = $rec->('install_driver');
  local *Rex::GPU::NVIDIA::install_container_toolkit = $rec->('install_container_toolkit');
  local *Rex::GPU::NVIDIA::generate_cdi_specs        = $rec->('generate_cdi_specs');
  local *Rex::GPU::NVIDIA::configure_containerd      = $rec->('configure_containerd');
  local *Rex::GPU::NVIDIA::verify_nvidia             = $rec->('verify_nvidia');
  local *Rex::Logger::info = sub { push @logs, [ $_[1] // 'info', $_[0] ] };
  local *Rex::get_current_connection = sub { return };
  my $ret = Rex::GPU::gpu_setup(@opts);
  return { ret => $ret, calls => \@calls, logs => \@logs, detect_calls => $detect_calls };
}

sub steps { my ( $r ) = @_; [ map { $_->[0] } @{ $r->{calls} } ] }
sub warns { my ( $r ) = @_; [ map { $_->[1] } grep { $_->[0] eq 'warn' } @{ $r->{logs} } ] }
sub driver_args { my ( $r ) = @_; my ( $c ) = grep { $_->[0] eq 'install_driver' } @{ $r->{calls} }; return { @{$c}[1 .. $#$c] } }

my $ADA    = { name => 'NVIDIA RTX 4000 SFF Ada Generation', device_id => '27b0', compute => 1 };
my $KEPLER = { name => 'NVIDIA Tesla K80', device_id => '102d', compute => 0 };
my $AMD    = { name => 'AMD Radeon Pro W7600', vendor => 'amd' };

sub hosts { my ( %h ) = @_; return { nvidia => [], amd => [], nvswitch => [], %h } }

subtest 'no GPU: nothing runs, no warning' => sub {
  my $d = hosts();
  my $r = setup_with($d);
  is_deeply(steps($r), [], 'no pipeline step');
  is_deeply(warns($r), [], 'no warning');
  is($r->{ret}, $d, 'returns the detection result');
  is($r->{detect_calls}, 1, 'detects once');
};

subtest 'AMD only: nothing runs, exactly one warning' => sub {
  my $r = setup_with(hosts(amd => [ $AMD ]), reboot => 1);
  is_deeply(steps($r), [], 'no install_driver, no pipeline step');
  is(scalar(@{ warns($r) }), 1, 'exactly one warning');
  like(warns($r)->[0], qr/AMD GPU detected .* not yet implemented/, '... AMD driver support not implemented');
};

subtest 'NVIDIA without a compute GPU: nothing runs, no warning from gpu_setup' => sub {
  my $r = setup_with(hosts(nvidia => [ $KEPLER ]), reboot => 1);
  is_deeply(steps($r), [], 'no pipeline step');
  is_deeply(warns($r), [], 'no warning');
};

subtest 'compute GPU: the full pipeline in order' => sub {
  my $r = setup_with(hosts(nvidia => [ $KEPLER, $ADA ]));
  is_deeply(steps($r), \@STEPS, 'driver, toolkit, CDI, containerd, verify');
  is_deeply(driver_args($r), { reboot => 0, gpus => [ $ADA ] }, 'install_driver: compute GPUs only, reboot => 0');
  is_deeply($r->{calls}[3], [ 'configure_containerd', 'rke2' ], 'containerd_config defaults to rke2');
  is_deeply(warns($r), [], 'no warning');
};

subtest 'reboot is passed through as 1/0' => sub {
  is(driver_args(setup_with(hosts(nvidia => [ $ADA ]), reboot => 1))->{reboot}, 1, 'reboot => 1 => 1');
  is(driver_args(setup_with(hosts(nvidia => [ $ADA ]), reboot => 'yes'))->{reboot}, 1, 'reboot => "yes" => 1');
  is(driver_args(setup_with(hosts(nvidia => [ $ADA ]), reboot => 0))->{reboot}, 0, 'reboot => 0 => 0');
};

subtest "containerd_config => 'none' skips configure_containerd" => sub {
  my $r = setup_with(hosts(nvidia => [ $ADA ]), containerd_config => 'none');
  is_deeply(steps($r), [ grep { $_ ne 'configure_containerd' } @STEPS ], 'every other step still runs');
  $r = setup_with(hosts(nvidia => [ $ADA ]), containerd_config => 'k3s');
  is_deeply($r->{calls}[3], [ 'configure_containerd', 'k3s' ], 'k3s is passed on');
};

subtest 'unknown containerd_config dies before detection' => sub {
  for my $d (hosts(nvidia => [ $ADA ]), hosts()) {
    my $r = eval { setup_with($d, containerd_config => 'bogus') };
    is($@, "Unknown containerd runtime: bogus (valid: rke2, k3s, containerd, none)\n",
      'dies naming the value and the valid ones');
  }
  my ( $detect_calls, @calls ) = ( 0 );
  {
    no warnings 'redefine';
    local *Rex::GPU::gpu_detect = sub { $detect_calls++; return hosts(nvidia => [ $ADA ]) };
    local *Rex::GPU::NVIDIA::install_driver = sub { push @calls, 'install_driver' };
    local *Rex::get_current_connection = sub { return };
    eval { Rex::GPU::gpu_setup(containerd_config => 'RKE2') };
  }
  is($detect_calls, 0, 'no detection');
  is_deeply(\@calls, [], 'no install_driver');
  for my $ok (qw( rke2 k3s containerd none )) {
    my $r = eval { setup_with(hosts(nvidia => [ $ADA ]), containerd_config => $ok) };
    is($@, '', "$ok is accepted");
  }
};

subtest 'NVIDIA next to AMD: pipeline plus one AMD warning' => sub {
  my $r = setup_with(hosts(nvidia => [ $ADA ], amd => [ $AMD ]));
  is_deeply(steps($r), \@STEPS, 'full pipeline');
  is(scalar(@{ warns($r) }), 1, 'exactly one warning');
  like(warns($r)->[0], qr/AMD GPU detected/, '... the AMD one');
};

done_testing;
