use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# k49: a re-run against a running rke2 used to get `systemctl start`, a no-op,
# so a changed config.yaml, registries.yaml, /etc/default PATH, containerd
# drop-in or new binary waited for the next reboot. start_verb now restarts a running rke2 (server and agent) exactly
# when restart_reasons finds something newer than its main process, and logs
# why; nothing changed keeps `start`. k3s is restarted on every run, as
# before, and is not asked. An upgraded nvidia-container-runtime binary is
# no reason (k56): containerd runs it anew per container. Whether a new
# binary may be restarted onto at all (version skew, an unpinned new minor
# is held) is t/version-skew.t; the new binaries here are patch releases.
#
# run is faked: this proves the decision, the commands that ask the host and
# the log line. That `find -newermt`, `ps -o etimes=` and `/proc/PID/exe
# --version` answer like this on a real node is only shown by a live run.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::Distribution;

my $D = 'Rex::Rancher::Distribution';

my @perl_warnings;
$SIG{__WARN__} = sub { push @perl_warnings, @_ };

# %host: pid (MainPID, 0 = not running), since (ps answer, undef = ps fails),
# changed (find -newermt output), runtime (what a find -newerct on the NVIDIA
# runtime would answer), running and installed (--version output).
my ( @log, @info, @warn, %host );
{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    return "MainPID=" . ( $host{pid} // 0 ) . "\n" if $cmd =~ /^systemctl show -p MainPID /;
    if ( $cmd =~ /ps -o etimes=/ ) {
      return "$host{since}\n" if defined $host{since};
      $? = 1 << 8;
      return '';
    }
    return $host{changed} // '' if $cmd =~ /-newermt /;
    return $host{runtime} // '' if $cmd =~ /-newerct /;
    return $host{running} // '' if $cmd =~ m{^/proc/\d+/exe --version};
    return $host{installed} // '' if $cmd =~ /^(?:rke2|k3s) --version/;
    return "active\n"   if $cmd =~ /^systemctl is-active /;
    return "yes\n"      if $cmd =~ /^test -f/;
    return "/usr/local/bin/rke2\n" if $cmd =~ /^command -v rke2/;
    return '';
  };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  *Rex::Rancher::Agent::run   = $run;
  *Rex::Logger::info = sub { push @{ ( $_[1] // '' ) eq 'warn' ? \@warn : \@info }, $_[0] };
}

# Installed: `rke2 --version`. Running: `/proc/PID/exe --version`, where the
# binary answers as "exe" (k68).
my $V1 = "rke2 version v1.30.4+rke2r1 (abc)\ngo version go1.22.5\n";
my $V2 = "rke2 version v1.31.1+rke2r1 (def)\ngo version go1.22.5\n";
my $V1P = "rke2 version v1.30.5+rke2r1 (fed)\ngo version go1.22.5\n";
my $R1 = "exe version v1.30.4+rke2r1 (abc)\ngo version go1.22.5\n";
my %QUIET = ( pid => 4242, since => 1790000000, running => $R1, installed => $V1 );

sub reset_host { %host = @_; ( @log, @info, @warn ) = () }

subtest 'parse_main_pid' => sub {
  is( $D->parse_main_pid("MainPID=4242\n"), 4242, 'a PID' );
  is( $D->parse_main_pid("MainPID=0\n"), undef, '0: not running' );
  is( $D->parse_main_pid(''), undef, 'no output' );
  is( $D->parse_main_pid(undef), undef, 'undef' );
  is( $D->parse_main_pid("Foo=1\nMainPID=17\n"), 17, 'among other lines' );
};

subtest 'restart_watch' => sub {
  is_deeply( [ $D->new_for('rke2')->restart_watch ], [
    '/etc/rancher/rke2/config.yaml',
    '/etc/rancher/rke2/config.yaml.d',
    '/etc/rancher/rke2/registries.yaml',
    '/etc/default/rke2-server',
    '/var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl',
    '/var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.tmpl',
    '/var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.d',
  ], 'rke2 server' );
  is( ( $D->new_for( 'rke2', role => 'agent' )->restart_watch )[3], '/etc/default/rke2-agent',
    'rke2 agent: its own env file' );
  is_deeply( [ $D->new_for('k3s')->restart_watch ], [
    '/etc/rancher/k3s/config.yaml',
    '/etc/rancher/k3s/config.yaml.d',
    '/etc/rancher/k3s/registries.yaml',
    '/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl',
    '/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.tmpl',
    '/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.d',
  ], 'k3s: no env file' );
};

my $rke2 = $D->new_for('rke2');

subtest 'not running: start, nothing else asked' => sub {
  reset_host( pid => 0 );
  is_deeply( [ $rke2->restart_reasons ], [], 'no reasons' );
  is_deeply( [ grep { !/config\.toml/ } @log ], [ 'systemctl show -p MainPID rke2-server 2>/dev/null' ],
    'only MainPID asked' );
  reset_host( pid => 0 );
  is( $rke2->start_verb, 'start', 'verb' );
  is_deeply( [ @info, @warn ], [], 'nothing logged' );
};

subtest 'running, nothing changed: start (a re-run leaves it alone)' => sub {
  reset_host(%QUIET);
  is( $rke2->start_verb, 'start', 'verb' );
  is_deeply( [ @info, @warn ], [], 'nothing logged' );
  my ($find) = grep { /-newermt / } @log;
  is( $find, "find '" . join( "' '", $rke2->restart_watch ) . "' -newermt \@1790000000 2>/dev/null",
    'every watched path, newer than the process start' );
  ok( ( grep { $_ eq 'echo $(( $(date +%s) - $(ps -o etimes= -p 4242) ))' } @log ),
    'process start from the host clock and ps' );
  ok( ( grep { $_ eq '/proc/4242/exe --version 2>&1' } @log ), 'running binary asked through /proc' );
  ok( !( grep { /nvidia-container-runtime|-newerct/ } @log ), 'the NVIDIA runtime binary is not asked (k56)' );
};

subtest 'config.yaml changed: restart, and the log says why' => sub {
  reset_host( %QUIET, changed => "/etc/rancher/rke2/config.yaml\n" );
  is( $rke2->start_verb, 'restart', 'verb' );
  is( scalar @info, 1, 'one line' );
  like( $info[0], qr{^Restarting rke2-server, which reads these only when it starts: changed since it started: /etc/rancher/rke2/config\.yaml$},
    'names service and file' );
  is_deeply( \@warn, [], 'no warning' );
};

subtest 'several paths changed: all named' => sub {
  reset_host( %QUIET, changed => "/etc/rancher/rke2/registries.yaml\n/etc/default/rke2-server\n"
    . "/var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.d/99-nvidia.toml\n" );
  is_deeply( [ $rke2->restart_reasons ], [ 'changed since it started: /etc/rancher/rke2/registries.yaml, '
    . '/etc/default/rke2-server, /var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.d/99-nvidia.toml' ],
    'one reason, every path' );
};

subtest 'nvidia-container-runtime upgraded after the start: no restart (k56)' => sub {
  reset_host( %QUIET, runtime => "/usr/bin/nvidia-container-runtime\n" );
  is_deeply( [ $rke2->restart_reasons ], [], 'a package upgrade of the runtime is no reason' );
  is( $rke2->start_verb, 'start', 'the control plane keeps running' );
  reset_host( %QUIET, runtime => "/usr/bin/nvidia-container-runtime\n",
    changed => "/var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.d/99-nvidia.toml\n" );
  is_deeply( [ $rke2->restart_reasons ], [ 'changed since it started: '
    . '/var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.d/99-nvidia.toml' ],
    'its registration (the drop-in) still is' );
  reset_host( %QUIET, changed => "/etc/default/rke2-server\n" );
  is_deeply( [ $rke2->restart_reasons ], [ 'changed since it started: /etc/default/rke2-server' ],
    'and so is the PATH line in the env file' );
};

subtest 'new binary installed' => sub {
  reset_host( %QUIET, installed => $V2 );
  is_deeply( [ $rke2->restart_reasons ], [ 'it runs v1.30.4+rke2r1, v1.31.1+rke2r1 is installed' ],
    'reason' );
  reset_host( %QUIET, changed => "/etc/rancher/rke2/config.yaml\n", installed => $V2 );
  is( scalar( () = $rke2->restart_reasons ), 2, 'with a config change: both' );
};

subtest 'undeterminable: unchanged, but said loudly' => sub {
  reset_host( %QUIET, since => undef );
  is( $rke2->start_verb, 'start', 'no ps: start' );
  ok( !( grep { /-newer/ } @log ), 'no find without a start time' );
  is( scalar @warn, 1, 'one warning' );
  like( $warn[0], qr{^Could not tell when rke2-server started .*config\.yaml.* restart rke2-server yourself},
    'names what is not detected' );

  reset_host( %QUIET, since => undef, installed => $V1P );
  is( $rke2->start_verb, 'restart', 'no ps, new binary: still restart' );

  reset_host( %QUIET, running => "exec failed\n" );
  is( $rke2->start_verb, 'start', 'running version unknown: start' );
  like( join( "\n", @warn ), qr{Could not compare the running rke2-server .*restart rke2-server yourself after an upgrade},
    'warned' );
};

subtest 'rke2 agent: same checks on its own unit' => sub {
  reset_host( %QUIET, changed => "/etc/default/rke2-agent\n" );
  my $agent = $D->new_for( 'rke2', role => 'agent' );
  is( $agent->start_verb, 'restart', 'verb' );
  like( $info[0], qr{^Restarting rke2-agent\.service, which reads these only when it starts: changed since it started: /etc/default/rke2-agent$},
    'log' );
};

subtest 'k3s: restart on every run, only the version skew asked' => sub {
  for my $role (qw( server agent )) {
    reset_host( %QUIET, running => "exe version v1.30.4+k3s1 (4dedb15b)\ngo version go1.22.5\n",
      installed => "k3s version v1.30.4+k3s1 (4dedb15b)\ngo version go1.22.5\n" );
    is( $D->new_for( 'k3s', role => $role )->start_verb, 'restart', $role.': verb' );
    ok( !( grep { /-newermt|etimes/ } @log ), $role.': no change detection' );
    is_deeply( [ @info, @warn ], [], $role.': nothing logged' );
  }
};

subtest 'stale Rex::GPU 0.001 containerd config wins, asked no further' => sub {
  reset_host( %QUIET, changed => "/etc/rancher/rke2/config.yaml\n" );
  no warnings 'redefine';
  local *Rex::Commands::Run::run = do {
    my $inner = \&Rex::Commands::Run::run;
    sub {
      my ( $cmd ) = @_;
      if ( $cmd =~ m{^cat \S+/config\.toml } ) { push @log, $cmd; $? = 0; return qq{imports = []\nversion = 2\n} }
      if ( $cmd =~ m{^test -e .*config\.toml\.tmpl$} ) { push @log, $cmd; $? = 256; return '' }
      if ( $cmd =~ m{^systemctl is-active --quiet} ) { push @log, $cmd; $? = 0; return '' }
      return $inner->(@_);
    };
  };
  is( $rke2->start_verb, 'restart', 'verb' );
  ok( !( grep { /-newermt|etimes/ } @log ), 'restart_reasons not asked' );
  is( scalar @warn, 1, 'only the stale-config warning' );
};

# Wired into the start steps of server and agent.
reset_host( %QUIET, changed => "/etc/rancher/rke2/config.yaml\n" );
Rex::Rancher::Server::_install( $D->new_for('rke2'), undef, undef, 'script' );
is_deeply( [ grep { /^systemctl (?:start|restart)/ } @log ], [ 'systemctl restart --no-block rke2-server' ],
  'rke2 server, changed config: restart --no-block' );

reset_host(%QUIET);
Rex::Rancher::Server::_install( $D->new_for('rke2'), undef, undef, 'script' );
is_deeply( [ grep { /^systemctl (?:start|restart)/ } @log ], [ 'systemctl start --no-block rke2-server' ],
  'rke2 server, nothing changed: start, the running server is left alone' );

reset_host( %QUIET, installed => $V1P );
Rex::Rancher::Agent::_enable_service( $D->new_for( 'rke2', role => 'agent' ), 'https://cp:9345' );
is_deeply( [ grep { /^systemctl (?:start|restart)/ } @log ], [ 'systemctl restart --no-block rke2-agent.service' ],
  'rke2 agent, new binary: restart --no-block' );

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
