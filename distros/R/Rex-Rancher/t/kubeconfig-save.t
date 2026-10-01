use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );

use Rex::Rancher;

# _save_kubeconfig_locally with kubeconfig_file given: a failed fetch or
# write dies naming the cause, and rancher_deploy_server stops before
# wait_for_api, Cilium and the device plugin. Offline: get_kubeconfig and
# every remote/API step are fakes.

my $dir = tempdir( CLEANUP => 1 );
my $kc_file = $dir.'/kc.yaml';
our $remote_kc = "server: https://127.0.0.1:6443\n";

my @ran;
no warnings 'redefine';
local *Rex::Rancher::Server::get_kubeconfig = sub {
  push @ran, 'get_kubeconfig';
  die "cat: /etc/rancher/rke2/rke2.yaml: No such file\n" unless defined $remote_kc;
  $remote_kc;
};
local *Rex::Rancher::_check_connection           = sub { push @ran, 'check_connection' };
local *Rex::Rancher::prepare_node                = sub { push @ran, 'prepare_node' };
local *Rex::Rancher::install_server              = sub { push @ran, 'install_server' };
local *Rex::Rancher::wait_for_api                = sub { push @ran, 'wait_for_api'; 1 };
local *Rex::Rancher::install_cilium              = sub { push @ran, 'install_cilium' };
local *Rex::Rancher::deploy_nvidia_device_plugin = sub { push @ran, 'device_plugin' };
my @log;
local *Rex::Logger::info = sub { push @log, [ $_[1] // 'info', $_[0] ] };
use warnings 'redefine';

# The file holds the admin client certificate and key: 0600 whatever the
# umask, including over a file an earlier version left 0644.
umask 022;

# Unit: the function itself.
@ran = ();
is(Rex::Rancher::_save_kubeconfig_locally('rke2', undef), undef,
  'no kubeconfig_file: nothing fetched, undef');
is_deeply(\@ran, [], 'no kubeconfig_file: get_kubeconfig not called');

is(Rex::Rancher::_save_kubeconfig_locally('rke2', $kc_file, tls_san => 'cp.example.com'),
  $kc_file, 'fetched and written: returns the file');
open(my $fh, '<', $kc_file) or die $!;
like(do { local $/; <$fh> }, qr{https://cp\.example\.com:6443}, 'written file is patched');
close $fh;
is(( stat $kc_file )[2] & 07777, 0600, 'written file is 0600 under umask 022');

{
  my $old = $dir.'/old.yaml';
  open(my $ofh, '>', $old) or die $!;
  print $ofh "stale\n";
  close $ofh;
  chmod 0644, $old;
  Rex::Rancher::_save_kubeconfig_locally('rke2', $old, tls_san => 'cp.example.com');
  is(( stat $old )[2] & 07777, 0600, 'an existing 0644 file ends up 0600');
  open(my $rfh, '<', $old) or die $!;
  like(do { local $/; <$rfh> }, qr{\Aserver: https://cp\.example\.com:6443\n\z},
    'an existing file is replaced, not appended to');
  close $rfh;
}

# The address warnings, word for word, and where they fall in the log: after
# the fetch, before "Kubeconfig saved to".
my $no_addr_warn = "Kubeconfig saved to $kc_file but no server address could be "
  . "derived — it still points at https://127.0.0.1 and will not reach "
  . "the cluster from this machine; pass tls_san or kubeconfig_server";
my $loop_warn = sub {
  "Kubeconfig server address '$_[0]' is a loopback address — the "
    . "kubeconfig saved to $kc_file will still point at the loopback "
    . "interface and will not reach the cluster from this machine; pass "
    . "a routable tls_san or kubeconfig_server";
};
my $saved = [ info => "Kubeconfig saved to $kc_file" ];
my $read_kc = sub { open(my $r, '<', $kc_file) or die $!; local $/; <$r> };

@log = ();
Rex::Rancher::_save_kubeconfig_locally('rke2', $kc_file);
is_deeply([ grep { $_->[1] !~ /^Retrieving kubeconfig/ } @log ],
  [ [ warn => $no_addr_warn ], $saved ], 'no address: the warning, then saved');
is($read_kc->(), $remote_kc, 'no address: saved as the node wrote it');

for my $lo (qw( 127.0.0.1 localhost LOCALHOST ::1 )) {
  @log = ();
  Rex::Rancher::_save_kubeconfig_locally('rke2', $kc_file, kubeconfig_server => $lo);
  is_deeply([ grep { $_->[1] !~ /^Retrieving kubeconfig/ } @log ],
    [ [ warn => $loop_warn->($lo) ], $saved ], 'loopback '.$lo.': the warning, then saved');
}

@log = ();
Rex::Rancher::_save_kubeconfig_locally('rke2', $kc_file, tls_san => [ 'cp.example.com', 'x' ]);
is_deeply([ grep { $_->[1] !~ /^Retrieving kubeconfig/ } @log ], [ $saved ],
  'routable address: no warning');

Rex::Rancher::_save_kubeconfig_locally('rke2', $kc_file, kubeconfig_server => '2001:db8::1');
is($read_kc->(), "server: https://[2001:db8::1]:6443\n", 'IPv6 kubeconfig_server: in brackets');

# The dies, word for word: what the host is in, and how to go on.
my $stopped = sub {
  "; $_[0] server is installed, Cilium and later steps did not run. Fix the "
    . "cause and re-run, or omit kubeconfig_file to install Cilium through "
    . "the remote host only\n";
};

{
  local $remote_kc;
  @log = ();
  ok(!eval { Rex::Rancher::_save_kubeconfig_locally('rke2', $kc_file); 1 }, 'fetch fails: dies');
  is($@, "Could not fetch the kubeconfig from the rke2 server "
    . "(cat: /etc/rancher/rke2/rke2.yaml: No such file)".$stopped->('rke2'),
    'fetch fails: the whole message');
  is_deeply([ grep { $_->[0] eq 'warn' } @log ], [], 'fetch fails: no address warning');
}
{
  local $remote_kc = '';
  ok(!eval { Rex::Rancher::_save_kubeconfig_locally('k3s', $kc_file); 1 }, 'empty: dies');
  is($@, "Could not fetch the kubeconfig from the k3s server (empty file)".$stopped->('k3s'),
    'empty: the whole message');
}
{
  my $bad = $dir.'/missing/dir/kc.yaml';
  open(my $probe, '>', $bad) and die 'expected '.$bad.' to be unwritable';
  my $errno = "$!";
  ok(!eval { Rex::Rancher::_save_kubeconfig_locally('k3s', $bad, tls_san => 'cp'); 1 },
    'write fails: dies');
  is($@, "Could not write the kubeconfig to $bad: $errno".$stopped->('k3s'),
    'write fails: the whole message');
}

{
  local $remote_kc;
  ok(!eval { Rex::Rancher::_save_kubeconfig_locally('rke2', $kc_file); 1 }, 'fetch fails: dies');
  like($@, qr/Could not fetch the kubeconfig from the rke2 server \(cat: .*No such file\)/,
    'fetch fails: names the error');
  like($@, qr/rke2 server is installed, Cilium and later steps did not run/,
    'fetch fails: says what state the host is in');
}
{
  local $remote_kc = '';
  ok(!eval { Rex::Rancher::_save_kubeconfig_locally('k3s', $kc_file); 1 }, 'empty kubeconfig: dies');
  like($@, qr/from the k3s server \(empty file\)/, 'empty kubeconfig: says so');
}

my $bad_file = $dir.'/missing/dir/kc.yaml';
ok(!eval { Rex::Rancher::_save_kubeconfig_locally('rke2', $bad_file, tls_san => 'cp'); 1 },
  'write fails: dies');
like($@, qr/Could not write the kubeconfig to \Q$bad_file\E: /, 'write fails: names the file');

# Pipeline: nothing after the save runs, on either distribution.
for my $dist (qw( rke2 k3s )) {
  for my $case (
    [ 'fetch fails', $kc_file,  undef ],
    [ 'write fails', $bad_file, $remote_kc ]
  ) {
    my ( $name, $file, $content ) = @$case;
    local $remote_kc = $content;
    @ran = ();
    ok(!eval {
      Rex::Rancher::rancher_deploy_server(distribution => $dist, kubeconfig_file => $file,
        tls_san => 'cp.example.com', gpu => 1, gpu_setup => 0);
      1;
    }, $dist.', '.$name.': deploy dies');
    unlike($@, qr/gateway_api/, $dist.', '.$name.': not the gateway_api message');
    is_deeply(\@ran,
      [qw( check_connection prepare_node install_server get_kubeconfig )],
      $dist.', '.$name.': no wait_for_api, Cilium or device plugin');
  }
}

# The gateway_api case the ticket was about: the kubeconfig error, not
# "gateway_api needs kubeconfig".
{
  local $remote_kc;
  @ran = ();
  ok(!eval {
    Rex::Rancher::rancher_deploy_server(kubeconfig_file => $kc_file, tls_san => 'cp',
      gateway_api => 1, gateway_api_version => 'v1.2.0');
    1;
  }, 'gateway_api, fetch fails: dies');
  like($@, qr/Could not fetch the kubeconfig/, 'gateway_api, fetch fails: the kubeconfig error');
}

done_testing;
