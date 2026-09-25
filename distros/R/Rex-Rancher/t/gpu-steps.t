use strict;
use warnings;
use Test::More;

use Rex::Rancher;

# Which GPU steps the pipelines run, and that Rex::GPU is only loaded when its
# gpu_setup actually runs. Offline: every remote step is replaced by a fake.

my %steps_for = (
  'no gpu'                              => [ {},                                                    0, 0, 0 ],
  'gpu => 0 ignores the switches'       => [ { gpu => 0, gpu_setup => 0, gpu_device_plugin => 1 },  0, 0, 0 ],
  'gpu => 1 runs both (default)'        => [ { gpu => 1 },                                          1, 1, 0 ],
  'gpu_setup => 0'                      => [ { gpu => 1, gpu_setup => 0 },                          0, 1, 1 ],
  'gpu_device_plugin => 0'              => [ { gpu => 1, gpu_device_plugin => 0 },                  1, 0, 0 ],
  'operator: both off'                  => [ { gpu => 1, gpu_setup => 0, gpu_device_plugin => 0 },  0, 0, 1 ]
);
for my $name (sort keys %steps_for) {
  my ( $opts, $setup, $plugin, $path ) = @{ $steps_for{$name} };
  my %steps = Rex::Rancher::_gpu_steps(%$opts);
  is_deeply(\%steps, { setup => $setup, device_plugin => $plugin, runtime_path => $path }, $name);
}

# What install_server/install_agent get: the rke2 unit PATH only when the host
# brings its own toolkit (gpu_setup => 0); an explicit value always wins.
my %runtime_path_for = (
  'no gpu'                          => [ {},                                                   0 ],
  'gpu => 1 (Rex::GPU wires it)'    => [ { gpu => 1 },                                         0 ],
  'gpu => 1, gpu_setup => 0'        => [ { gpu => 1, gpu_setup => 0 },                         1 ],
  'explicit 0 wins'                 => [ { gpu => 1, gpu_setup => 0, nvidia_runtime_path => 0 }, 0 ],
  'explicit 1 without gpu'          => [ { nvidia_runtime_path => 1 },                         1 ]
);
for my $name (sort keys %runtime_path_for) {
  my ( $opts, $want ) = @{ $runtime_path_for{$name} };
  my %got = Rex::Rancher::_install_opts(%$opts, token => 't');
  is($got{nvidia_runtime_path}, $want, "install opts, $name");
  is($got{token}, 't', "install opts, $name: other options passed through");
}

# Rex::GPU loads only through this hook, which serves a fake that records the
# gpu_setup call. Nothing real is on disk under that name for the test.
delete $INC{'Rex/GPU.pm'};
my @gpu_loads;
our @gpu_setup_calls;
unshift @INC, sub {
  my ( undef, $file ) = @_;
  return unless $file eq 'Rex/GPU.pm';
  push @gpu_loads, $file;
  my $src = 'package Rex::GPU; sub import {} '
    .'sub gpu_setup { push @main::gpu_setup_calls, {@_} } 1;';
  open my $fh, '<', \$src or die;
  return $fh;
};

# Every remote/API step of both pipelines, faked; @ran records the order.
my @ran;
no warnings 'redefine';
local *Rex::Rancher::_check_connection           = sub { push @ran, 'check_connection' };
local *Rex::Rancher::prepare_node                = sub { push @ran, 'prepare_node' };
our %install_opts;
local *Rex::Rancher::install_server              = sub { push @ran, 'install_server'; %install_opts = @_ };
local *Rex::Rancher::install_agent               = sub { push @ran, 'install_agent'; %install_opts = @_ };
local *Rex::Rancher::_save_kubeconfig_locally    = sub { push @ran, 'save_kubeconfig'; $_[1] };
local *Rex::Rancher::wait_for_api                = sub { push @ran, 'wait_for_api'; 1 };
local *Rex::Rancher::install_cilium              = sub { push @ran, 'install_cilium' };
local *Rex::Rancher::deploy_nvidia_device_plugin = sub { push @ran, 'device_plugin' };
use warnings 'redefine';

sub reset_run { @ran = (); @gpu_loads = (); @gpu_setup_calls = (); delete $INC{'Rex/GPU.pm'} }

my %server = ( kubeconfig_file => '/nonexistent/kc.yaml' );

# Operator case: nothing GPU-side runs, Rex::GPU is never required.
reset_run();
Rex::Rancher::rancher_deploy_server(%server, gpu => 1, gpu_setup => 0, gpu_device_plugin => 0, reboot => 1);
is_deeply(\@gpu_loads, [], 'server, operator: Rex::GPU not required');
ok(!exists $INC{'Rex/GPU.pm'}, 'server, operator: Rex::GPU not in %INC');
is_deeply(\@ran,
  [qw( check_connection prepare_node install_server save_kubeconfig wait_for_api install_cilium )],
  'server, operator: no device plugin');

reset_run();
Rex::Rancher::rancher_deploy_agent(gpu => 1, gpu_setup => 0, server => 'https://cp:9345', token => 't');
is_deeply(\@gpu_loads, [], 'agent, gpu_setup => 0: Rex::GPU not required');
is_deeply(\@ran, [qw( check_connection prepare_node install_agent )], 'agent, gpu_setup => 0: prepare + join only');
is($install_opts{nvidia_runtime_path}, 1, 'agent, gpu_setup => 0: install_agent writes the unit PATH');

# Default gpu => 1: Rex::GPU's gpu_setup runs between prepare_node and the install.
reset_run();
Rex::Rancher::rancher_deploy_server(%server, gpu => 1, distribution => 'k3s', reboot => 1,
  tls_san => '10.0.0.1');
is(scalar @gpu_loads, 1, 'server, gpu => 1: Rex::GPU required');
is_deeply(\@gpu_setup_calls, [ { containerd_config => 'k3s', reboot => 1 } ],
  'server, gpu => 1: gpu_setup gets distribution and reboot');
is($install_opts{nvidia_runtime_path}, 0, 'server, gpu => 1: no unit PATH, Rex::GPU wires the runtime');
is_deeply(\@ran,
  [qw( check_connection prepare_node install_server save_kubeconfig wait_for_api install_cilium device_plugin )],
  'server, gpu => 1: device plugin after Cilium');

# Host driver via Rex::GPU, device plugin left to the operator.
reset_run();
Rex::Rancher::rancher_deploy_server(%server, gpu => 1, gpu_device_plugin => 0);
is(scalar @gpu_setup_calls, 1, 'server, gpu_device_plugin => 0: gpu_setup still runs');
ok(!grep({ $_ eq 'device_plugin' } @ran), 'server, gpu_device_plugin => 0: no device plugin');

# Pre-installed driver, our device plugin.
reset_run();
Rex::Rancher::rancher_deploy_server(%server, gpu => 1, gpu_setup => 0);
is_deeply(\@gpu_loads, [], 'server, gpu_setup => 0: Rex::GPU not required');
is($ran[-1], 'device_plugin', 'server, gpu_setup => 0: device plugin still deployed');
is($install_opts{nvidia_runtime_path}, 1, 'server, gpu_setup => 0: install_server writes the unit PATH');

reset_run();
Rex::Rancher::rancher_deploy_agent(gpu => 1, server => 'https://cp:9345', token => 't');
is_deeply(\@gpu_setup_calls, [ { containerd_config => 'rke2', reboot => 0 } ],
  'agent, gpu => 1: gpu_setup runs with rke2 default');

# No gpu at all: unchanged, nothing GPU-related.
reset_run();
Rex::Rancher::rancher_deploy_server(%server);
is_deeply(\@gpu_loads, [], 'server, no gpu: Rex::GPU not required');
ok(!grep({ $_ eq 'device_plugin' } @ran), 'server, no gpu: no device plugin');

done_testing;
