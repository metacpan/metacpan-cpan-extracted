use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# k71 (from kubernetes-ocp k196/k190): Cilium's datapath outlives the vendor
# uninstallers. Until a reboot, the socket load balancer on the root cgroup
# (attached through /run/cilium/cgroupv2, its links pinned in
# /sys/fs/bpf/cilium) keeps translating the old cluster's service addresses to
# pods that are gone: connect() to e.g. a registry mirror on localhost:30500
# hangs instead of being refused, every image pull of a new install waits
# minutes, and a fresh rke2 does not get etcd up within its start bound.
# Measured by kubernetes-ocp on ocpt-cp; a reboot cleared it.
#
# So install_server and install_agent, rke2 and k3s alike, probe the host
# before anything is written or installed, and die on Cilium state when no
# RKE2/K3s is there (no binary on PATH, none of their units active). With a
# distribution the state belongs to the running cluster: not checked.
#
# run and file are faked. The probe's shell logic runs under /bin/sh with a
# PATH of stubs; it only reads (test -e, /proc/mounts, ip link show). That the
# signals are what a real leftover host shows is kubernetes-ocp's measurement,
# not shown here.
# -----------------------------------------------------------------------------

use File::Temp qw( tempdir );
use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::Uninstall ();

my $U = 'Rex::Rancher::Uninstall';

my @perl_warnings;
$SIG{__WARN__} = sub { push @perl_warnings, @_ };

# %host: probe (the probe's output), probe_exit (its exit status).
my ( @log, @warn, %host );
{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    if ( $cmd =~ m{/sys/fs/bpf/cilium} ) {
      $? = ( $host{probe_exit} // 0 ) << 8;
      return $host{probe} // '';
    }
    return "/usr/local/bin/$1\n" if $cmd =~ /^command -v (rke2|k3s)/;
    return "active\n"            if $cmd =~ /^systemctl is-active \S+\z/;
    return "yes\n"               if $cmd =~ /^test -f /;
    # A fresh host: no server set up, nothing to read, no channel.
    if ( $cmd =~ /^systemctl is-active --quiet / ) { $? = 3 << 8; return '' }
    if ( $cmd =~ /^(?:test -e |cat )/ )            { $? = 1 << 8; return '' }
    if ( $cmd =~ m{^curl -fsSL -o /dev/null } )    { $? = 6 << 8; return '' }
    return '';
  };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  *Rex::Rancher::Agent::run   = $run;
  my $file = sub { push @log, "file $_[0]" };
  *Rex::Commands::File::file  = $file;
  *Rex::Rancher::Server::file = $file;
  *Rex::Commands::File::get_tmp_file_name = sub { '/tmp/.rex.tmp' };
  *Rex::Logger::info = sub { push @warn, $_[0] if ( $_[1] // '' ) eq 'warn' };
}

sub reset_host { %host = @_; ( @log, @warn ) = () }

my %JOIN = (
  rke2 => 'https://10.0.0.1:9345',
  k3s  => 'https://10.0.0.1:6443',
);

my %install = (
  server => sub { install_server( distribution => $_[0], token => 't' ) },
  agent  => sub { install_agent( distribution => $_[0], server => $JOIN{ $_[0] }, token => 't' ) },
);

# ---- install_server / install_agent refuse a leftover host ------------------

for my $dist (qw( rke2 k3s )) {
  for my $role (qw( server agent )) {
    my $install = $install{$role};

    subtest "$dist $role: Cilium leftovers, no distribution: dies before anything is written" => sub {
      reset_host( probe => "/sys/fs/bpf/cilium\ncilium_host\n" );
      ok( !eval { $install->($dist); 1 }, 'dies' );
      my $err = $@;
      like( $err, qr/still carries Cilium datapath state from an earlier cluster/, 'saying why' );
      like( $err, qr{\(/sys/fs/bpf/cilium, cilium_host\)}, 'naming what it found' );
      like( $err, qr/no RKE2\/K3s is installed/, 'and that no distribution owns it' );
      like( $err, qr/socket load balancer/, 'the cause' );
      like( $err, qr/image pull/, 'the consequence' );
      like( $err, qr/Reboot the host, then run the install again\.\n\z/, 'and what to do' );
      like( $err, qr/Nothing was written or installed/, 'and that the host is as it was' );
      is( scalar @log, 1, 'the probe is the only command that ran' );
      like( $log[0] // '', qr{/sys/fs/bpf/cilium}, 'and it is the probe' );
    };

    subtest "$dist $role: a clean host (or one with a distribution): installs" => sub {
      reset_host( probe => '' );
      ok( eval { $install->($dist); 1 }, 'no die' ) or diag $@;
      like( $log[0] // '', qr{/sys/fs/bpf/cilium}, 'the probe ran first' );
      ok( ( grep { /get\.\Q$dist\E\.io/ } @log ), 'installer ran' );
      ok( ( grep { m{^file /etc/rancher/\Q$dist\E/config\.yaml\z} } @log ), 'config.yaml written' );
      is_deeply( [ grep { /Cilium/ } @warn ], [], 'no warning about Cilium' );
      is_deeply( [ grep { /uninstall/ } @log ], [], 'nothing is uninstalled on the way' );
    };

    subtest "$dist $role: a probe that cannot run warns and goes on" => sub {
      reset_host( probe => '', probe_exit => 127 );
      ok( eval { $install->($dist); 1 }, 'no die' ) or diag $@;
      like( join( "\n", @warn ), qr/Could not check this host for Cilium datapath state .*exited 127/,
        'says the host was not checked' );
      ok( ( grep { /get\.\Q$dist\E\.io/ } @log ), 'installer ran' );
    };
  }
}

subtest 'invalid options still die before the probe' => sub {
  reset_host( probe => "cilium_host\n" );
  ok( !eval { install_server( distribution => 'rke2', cluster_cidr => '10.42.0.0' ); 1 }, 'server dies' );
  like( $@, qr/cluster_cidr must be one IPv4 CIDR/, 'on the option' );
  ok( !eval { install_agent( distribution => 'k3s', server => $JOIN{k3s}, token => 't',
    install_method => 'artifact' ); 1 }, 'agent dies' );
  like( $@, qr/requires a version/, 'on the option' );
  is_deeply( \@log, [], 'the host was not probed' );
};

# ---- the probe's output: only its own lines count ---------------------------

subtest 'cilium_residue_in: only the probe\'s tokens' => sub {
  is_deeply( [ $U->cilium_residue_in('') ], [], 'empty: clean' );
  is_deeply( [ $U->cilium_residue_in(undef) ], [], 'undef: clean' );
  is_deeply( [ $U->cilium_residue_in("Welcome to host\n/sys/bus/pci/devices/0000:03:00.0|0x1002\n") ], [],
    'a banner and other noise are not Cilium state' );
  is_deeply( [ $U->cilium_residue_in("mesg: ttyname failed\n/sys/fs/bpf/cilium/foo\ncilium_hostx\n") ], [],
    'nor lines that only contain a name' );
  is_deeply(
    [ $U->cilium_residue_in("Last login: today\n  /sys/fs/bpf/cilium \r\n/run/cilium/cgroupv2\ncilium_host\n") ],
    [ '/sys/fs/bpf/cilium', '/run/cilium/cgroupv2', 'cilium_host' ],
    'the tokens, trimmed, in the order found' );
};

# ---- (c) one source: the probe and the uninstall test the same signals -----

my @residue = $U->cilium_residue;
my $probe   = $U->cilium_residue_probe_cmd;

subtest 'the residue signals' => sub {
  is_deeply( [ map { $_->[1] } @residue ], [ '/sys/fs/bpf/cilium', '/run/cilium/cgroupv2', 'cilium_host' ],
    'pins, cgroup2 mount, cilium_host' );
  is_deeply( [ map { $_->[0] } @residue ], [
    '[ -e /sys/fs/bpf/cilium ]',
    'grep -qs " /run/cilium/cgroupv2 " /proc/mounts',
    'ip link show dev cilium_host >/dev/null 2>&1',
  ], 'each read-only, over the exec channel' );
};

subtest 'the probe line' => sub {
  is( $probe, 'if command -v rke2 >/dev/null 2>&1 || command -v k3s >/dev/null 2>&1'
    . ' || systemctl is-active --quiet rke2-server rke2-agent.service k3s k3s-agent.service 2>/dev/null;'
    . ' then :; else'
    . ' [ -e /sys/fs/bpf/cilium ] && echo /sys/fs/bpf/cilium;'
    . ' grep -qs " /run/cilium/cgroupv2 " /proc/mounts && echo /run/cilium/cgroupv2;'
    . ' ip link show dev cilium_host >/dev/null 2>&1 && echo cilium_host;'
    . ' fi; true', 'no distribution: binary or active unit, rke2 and k3s; then the residue; always exit 0' );
  unlike( $probe, qr/\b(?:rm|del|umount|restore)\b/, 'reads only' );
};

subtest 'the install guard probes what the uninstall checks' => sub {
  my $uninstall = $U->uninstall_cmd;
  for my $r (@residue) {
    my ( $check, $label ) = @$r;
    like( $probe, qr/\Q$check\E && echo \Q$label\E;/, "probe checks $label" );
    like( $uninstall, qr/\Q$check\E && left="\$left \Q$label\E"/, "the uninstall's outcome checks $label the same way" );
  }
  is_deeply( [ sort map { $U->cilium_residue_in($_) } map { "$_->[1]\n" } @residue ],
    [ sort map { $_->[1] } @residue ], 'the guard counts exactly the residue names' );
};

# ---- the probe's shell logic -------------------------------------------------

# Runs the probe under /bin/sh with a PATH of nothing but stubs (and grep, for
# /proc/mounts). A stub logs "name args" to $STUB_LOG. The probe only reads.
sub spew {
  my ( $file, $content ) = @_;
  open my $fh, '>', $file or die "$file: $!";
  print {$fh} $content;
  close $fh;
}

sub slurp {
  my ( $file ) = @_;
  open my $fh, '<', $file or return '';
  local $/;
  my $content = <$fh>;
  return $content // '';
}

sub probe_with {
  my ( %stubs ) = @_;
  my $bin = tempdir( CLEANUP => 1 );
  my ( $grep ) = grep { -x } qw( /usr/bin/grep /bin/grep );
  symlink $grep, "$bin/grep" if $grep;
  for my $name (keys %stubs) {
    spew( "$bin/$name", "#!/bin/sh\necho \"$name \$*\" >> \"\$STUB_LOG\"\n".$stubs{$name} );
    chmod 0755, "$bin/$name";
  }
  my $log = tempdir( CLEANUP => 1 ).'/log';
  my ( $out, $exit ) = do {
    local $ENV{PATH}     = $bin;
    local $ENV{STUB_LOG} = $log;
    open my $fh, '-|', '/bin/sh', '-c', $probe or die "sh: $!";
    local $/;
    my $o = <$fh>;
    close $fh;
    ( $o, $? >> 8 );
  };
  return ( $out // '', $exit, slurp($log) );
}

SKIP: {
  skip 'needs a POSIX /bin/sh', 1 unless -x '/bin/sh';

  subtest 'the probe reports residue only without a distribution' => sub {
    my $ip = "case \"\$*\" in \"link show dev cilium_host\") exit 0;; esac\nexit 1\n";
    my ( $out, $exit, $log ) = probe_with( ip => $ip, systemctl => "exit 3\n" );
    like( $out, qr/^cilium_host$/m, 'no rke2/k3s: cilium_host is reported' );
    is( $exit, 0, 'and the probe exits 0' );
    like( $log, qr/^systemctl is-active --quiet rke2-server rke2-agent\.service k3s k3s-agent\.service$/m,
      'every server and agent unit of both distributions is asked' );

    for my $bin (qw( rke2 k3s )) {
      ( $out, $exit ) = probe_with( ip => $ip, systemctl => "exit 3\n", $bin => "exit 0\n" );
      is( $out, '', "$bin on PATH: the state is the cluster's own" );
      is( $exit, 0, "$bin on PATH: exits 0" );
    }
    ( $out ) = probe_with( ip => $ip, systemctl => "exit 0\n" );
    is( $out, '', 'a distribution unit active: likewise' );

    ( $out, $exit ) = probe_with( ip => "exit 1\n" );
    unlike( $out, qr/^cilium_host$/m, 'no cilium_host device: not reported' );
    is( $exit, 0, 'a failing check does not fail the probe' );
  };
}

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
