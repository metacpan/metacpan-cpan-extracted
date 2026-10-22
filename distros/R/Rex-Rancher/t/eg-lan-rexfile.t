use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use File::Spec;
use FindBin;
use Cwd qw( abs_path getcwd );
use JSON::MaybeXS qw( decode_json );

# -----------------------------------------------------------------------------
# Offline tests for the LAN live rig (eg/lan.Rexfile, karr k53).
#
# The card wants a live run on a LAN machine with a GTX-class consumer GPU.
# No such machine is in the fleet, so the live run cannot be done -- what can
# be done is everything around it, so that the run needs only the machine.
#
# What this proves:
#   * the Rexfile loads and exposes exactly the tasks its header documents
#     (deploy, rerun, cilium_upgrade, join_agent, check) plus the internal
#     join_token;
#   * the environment contract of the header: LAN_DIST is rke2 or k3s only
#     (anything else aborts the file before a task exists), LAN_GPU and
#     LAN_AGENT_GPU default to 0, LAN_SERVER is the tls_san, LAN_JOIN_URL
#     overrides the agent's join URL, LAN_CILIUM_UPGRADE_TO is required for
#     cilium_upgrade;
#   * the task bodies are wired: deploy hands its options to
#     rancher_deploy_server, join_agent to rancher_deploy_agent,
#     cilium_upgrade to upgrade_cilium -- with those lib calls replaced by
#     recorders, so nothing connects to anything;
#   * the check task asks for the control points of the card and redacts the
#     join token in the config.yaml dump;
#   * nothing Hetzner-specific is left in the rig (no host names, no
#     addresses, no SFTP dependency).
#
# What this does NOT prove:
#   * that a deploy works -- no host is contacted, the pipeline's steps never
#     run; a green suite here is no evidence for a deploy;
#   * the GPU path (Rex::GPU consumer classification, driver, containerd
#     drop-in, device plugin, nvidia.com/gpu): it needs the GTX-class card;
#   * the live-only steps of the card (cluster_cidr on a running cluster, the
#     re-run idempotency, the Cilium IPAM preservation, the agent join
#     against a real server) -- they stand in eg/lan.RUNBOOK.md.
#
# The task bodies run in a child process (a probe script written to a temp
# dir) with the lib calls replaced by recorders. The Rexfile is `require`d
# the way the rex CLI does it: `do` would swallow the die of a broken
# Rexfile and make it look like a loaded one.
# -----------------------------------------------------------------------------

my $ROOT    = abs_path( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $REXFILE = abs_path( File::Spec->catfile( $ROOT, 'eg', 'lan.Rexfile' ) );

plan skip_all => "eg/lan.Rexfile is not in this build ($ROOT)" unless $REXFILE && -f $REXFILE;

# the tasks of the header, and the internal one the header does not mention
my @HEADER_TASKS = qw( deploy rerun cilium_upgrade join_agent check );
my @ALL_TASKS    = ( @HEADER_TASKS, 'join_token' );

my $TMP = tempdir( CLEANUP => 1 );

# --- the probe ------------------------------------------------------------
#
# Loads the Rexfile, then runs one task body with the lib calls replaced by
# recorders. It answers with JSON on stdout: { ok, error, <mode> }.

my $PROBE = File::Spec->catfile( $TMP, 'probe.pl' );

open my $probe_fh, '>', $PROBE or die "cannot write $PROBE: $!\n";
print {$probe_fh} <<'PROBE_CODE';
use strict;
use warnings;
no warnings 'redefine';
use JSON::MaybeXS qw( encode_json );

my ( $file, $mode ) = @ARGV;

my $out = { mode => $mode, ok => 0 };

if ( !-f $file ) {
  $out->{error} = "no such file: $file";
  print encode_json($out);
  exit 4;
}

# require, not do: `do FILE` returns undef and leaves $@ empty when the file
# dies -- a broken Rexfile would look like a loaded one
my $loaded = eval { require $file; 1 };
if ($@) {
  $out->{error} = "$@";
  print encode_json($out);
  exit 3;
}
if ( !$loaded ) {
  $out->{error} = 'the Rexfile did not return a true value';
  print encode_json($out);
  exit 4;
}

# the tasks report the host they ran on -- fake it, nothing connects here
{
  package FakeConn;
  sub new    { return bless {}, shift }
  sub server { return $ENV{FAKE_SERVER} // '192.0.2.11' }
}
*main::connection = sub { return FakeConn->new };

require Rex::TaskList;
my $list = Rex::TaskList->create();

# run a task body with its say() output captured
sub run_body {
  my ( $code ) = @_;
  my $say = '';
  my $ok  = eval {
    open my $fh, '>', \$say or die "cannot capture output: $!\n";
    local *STDOUT = $fh;
    $code->();
    1;
  };
  return ( $ok, $say, $@ );
}

if ( $mode eq 'tasks' ) {
  my %tasks;
  for my $name ( $list->get_tasks ) {
    my $t = $list->get_task($name);
    $tasks{$name} = $t->desc // '';
  }
  $out->{tasks} = \%tasks;
  $out->{ok}    = 1;
}
elsif ( $mode eq 'deploy' ) {
  my ( @srv, @untaint );
  *main::rancher_deploy_server = sub { @srv     = @_; return 1 };
  *main::untaint_node         = sub { @untaint = @_; return 1 };
  my $t = $list->get_task('deploy');
  my ( $ok, $say, $err ) = run_body( $t->code );
  $out->{error}   = $err unless $ok;
  $out->{say}     = $say;
  $out->{server}  = { @srv };
  $out->{untaint} = { @untaint };
  $out->{ok}      = $ok ? 1 : 0;
}
elsif ( $mode eq 'join_agent' ) {
  my @agent;
  *main::rancher_deploy_agent = sub { @agent = @_; return 1 };
  my $t = $list->get_task('join_agent');
  my ( $ok, $say, $err ) = run_body( $t->code );
  $out->{error} = $err unless $ok;
  $out->{say}   = $say;
  $out->{agent} = { @agent };
  $out->{ok}    = $ok ? 1 : 0;
}
elsif ( $mode eq 'cilium_upgrade' ) {
  my @up;
  *main::upgrade_cilium = sub { @up = @_; return 1 };
  my $t = $list->get_task('cilium_upgrade');
  my ( $ok, $say, $err ) = run_body( $t->code );
  $out->{error}   = $err unless $ok;
  $out->{say}     = $say;
  $out->{upgrade} = { @up };
  $out->{ok}      = $ok ? 1 : 0;
}
elsif ( $mode eq 'check' ) {
  my @cmds;
  *main::run = sub {
    my ( $cmd ) = @_;
    push @cmds, $cmd;
    return "inactive\n";
  };
  my $t = $list->get_task('check');
  my ( $ok, $say, $err ) = run_body( $t->code );
  $out->{error} = $err unless $ok;
  $out->{say}   = $say;
  $out->{cmds}  = \@cmds;
  $out->{ok}    = $ok ? 1 : 0;
}
else {
  $out->{error} = "unknown mode $mode";
  print encode_json($out);
  exit 4;
}

print encode_json($out);
exit( $out->{ok} ? 0 : 3 );    # 3: the task body died
PROBE_CODE
close $probe_fh or die "cannot close $PROBE: $!\n";

# --- helpers --------------------------------------------------------------

# the child needs the same @INC as this process -- the working tree's lib
# first, so the repo copy of Rex::Rancher wins over an installed one
my @INC_ARGS = map { '-I'.File::Spec->catdir( $ROOT, $_ ) }
  grep { -d File::Spec->catdir( $ROOT, $_ ) } qw( lib blib/lib blib/arch );

for my $dir (@INC) {
  next if ref $dir;
  my $abs = File::Spec->file_name_is_absolute($dir) ? $dir : abs_path($dir);
  push @INC_ARGS, "-I$abs" if $abs && -d $abs;
}

my $KUBECONFIG = File::Spec->catfile( $TMP, 'kubeconfig.yaml' );

# run the probe in one mode, with the given environment
sub run_probe {
  my ( $mode, %env ) = @_;

  my %base = %ENV;
  delete $base{$_} for grep { /^LAN_/ } keys %base;
  $base{FAKE_SERVER} = '192.0.2.11';

  local %ENV = ( %base, %env );

  my $errfile = File::Spec->catfile( $TMP, "probe-$mode.err" );
  open my $olderr, '>&', \*STDERR or die "cannot dup STDERR: $!\n";
  open STDERR, '>', $errfile      or die "cannot write $errfile: $!\n";

  my $out = '';
  if ( open my $fh, '-|', $^X, @INC_ARGS, $PROBE, $REXFILE, $mode ) {
    local $/;
    $out = <$fh>;
    close $fh;
  }
  my $exit = $? >> 8;

  open STDERR, '>&', $olderr or die "cannot restore STDERR: $!\n";

  my $stderr = '';
  if ( open my $efh, '<', $errfile ) { local $/; $stderr = <$efh>; close $efh }

  my $data = eval { decode_json( $out // '' ) };
  return { exit => $exit, data => $data, stderr => $stderr, raw => $out };
}

# the recorded options of a task body
sub opts {
  my ( $res, $key ) = @_;
  return {} unless $res->{data} && $res->{data}->{$key};
  return $res->{data}->{$key};
}

# the rex CLI to use, if there is one
sub find_rex {
  return $ENV{REX_BIN} if $ENV{REX_BIN} && -x $ENV{REX_BIN};

  my @dirs = ( File::Spec->catdir( $ENV{HOME} // '', 'perl5', 'bin' ) );
  push @dirs, grep { length } split /:/, ( $ENV{PATH} // '' );
  push @dirs, '/usr/local/bin', '/usr/bin';

  for my $dir (@dirs) {
    my $c = File::Spec->catfile( $dir, 'rex' );
    return $c if -x $c;
  }
  return undef;
}

# run a command in the dist root -- the rex CLI wants the relative path
sub run_in_root {
  my ( @cmd ) = @_;

  my $old = getcwd();
  chdir $ROOT or die "cannot chdir to $ROOT: $!\n";

  my ( $out, $exit ) = ( '', 0 );
  my $ok = eval {
    if ( open my $fh, '-|', @cmd ) {
      local $/;
      $out = <$fh>;
      close $fh;
    }
    $exit = $? >> 8;
    1;
  };
  my $err = $@;

  chdir $old or die "cannot chdir back to $old: $!\n";
  die $err unless $ok;

  return ( $out, $exit );
}

# --- the tasks ------------------------------------------------------------

subtest 'the Rexfile exposes exactly the documented tasks' => sub {
  my $res = run_probe('tasks');
  is( $res->{exit}, 0, 'the Rexfile loads' ) or diag( $res->{raw} . $res->{stderr} );

  my %tasks = %{ $res->{data}{tasks} // {} };

  for my $name (@ALL_TASKS) {
    ok( exists $tasks{$name}, "the task $name exists" );
  }

  is_deeply(
    [ sort @ALL_TASKS ],
    [ sort keys %tasks ],
    'no other task than the documented ones and the internal join_token'
  );

  ok( length $tasks{join_token}, 'join_token has a description' );
  like( $tasks{join_token}, qr/internal/i, 'join_token is marked as internal' );
};

subtest 'the header documents the tasks that exist' => sub {
  open my $fh, '<', $REXFILE or die "cannot read $REXFILE: $!\n";
  my @lines = <$fh>;
  close $fh;

  my %documented;
  for my $line (@lines) {
    next unless $line =~ /^\s*#/;    # the usage lines of the header
    next unless $line =~ m{rex\s+-f\s+eg/lan\.Rexfile\s+(.*)$};
    my $rest = $1;
    $rest =~ s/#.*$//;    # the trailing comment of the usage line
    my @words = split ' ', $rest;
    next unless @words;
    my $task = $words[-1];
    next if $task =~ /^-/;    # -T is an option, not a task
    $documented{$task} = 1;
  }

  is_deeply(
    [ sort @HEADER_TASKS ],
    [ sort keys %documented ],
    'the usage lines of the header name exactly the documented tasks'
  );

  my $res = run_probe('tasks');
  my %tasks = %{ $res->{data}{tasks} // {} };
  for my $task ( sort keys %documented ) {
    ok( exists $tasks{$task}, "the documented task $task exists" );
  }
};

# --- the environment contract ---------------------------------------------

subtest 'LAN_DIST is rke2 or k3s only' => sub {
  for my $dist (qw( rke2 k3s )) {
    my $res = run_probe( 'tasks', LAN_DIST => $dist );
    is( $res->{exit}, 0, "LAN_DIST=$dist loads" )
      or diag( $res->{raw} . $res->{stderr} );
  }

  for my $dist (qw( nomad RKE2 rke2-server )) {
    my $res = run_probe( 'tasks', LAN_DIST => $dist );
    isnt( $res->{exit}, 0, "LAN_DIST='$dist' is refused" );
    like( $res->{data}{error} // '', qr/LAN_DIST must be rke2 or k3s/, 'the file says why' );
    ok( !exists $res->{data}{tasks}, 'no task is defined after the refusal' );
  }

  my $empty = run_probe( 'tasks', LAN_DIST => '' );
  is( $empty->{exit}, 0, 'an empty LAN_DIST is the default' )
    or diag( $empty->{raw} . $empty->{stderr} );
};

subtest 'the server options follow the environment' => sub {
  my %base = ( LAN_SERVER => '192.0.2.10', LAN_KUBECONFIG => $KUBECONFIG );

  my $res = run_probe( 'deploy', %base );
  is( $res->{exit}, 0, 'the deploy task runs offline' )
    or diag( $res->{raw} . $res->{stderr} );

  my $srv = opts( $res, 'server' );
  is( $srv->{distribution}, 'rke2', 'rke2 is the default distribution' );
  is( $srv->{gpu},         0,      'LAN_GPU defaults to 0' );
  is( $srv->{reboot},      0,      'no GPU, no reboot' );
  is( $srv->{tls_san}, '192.0.2.10', 'LAN_SERVER is the tls_san' );
  is( $srv->{kubeconfig_file}, $KUBECONFIG, 'the kubeconfig file is handed over' );
  is( opts( $res, 'untaint' )->{kubeconfig}, $KUBECONFIG, 'the node is untainted with it' );

  my $gpu = run_probe( 'deploy', %base, LAN_GPU => 1 );
  is( opts( $gpu, 'server' )->{gpu},    1, 'LAN_GPU=1 asks for a GPU' );
  is( opts( $gpu, 'server' )->{reboot}, 1, 'a GPU reboots the node' );

  my $no_reboot = run_probe( 'deploy', %base, LAN_GPU => 1, LAN_REBOOT => 0 );
  is( opts( $no_reboot, 'server' )->{reboot}, 0, 'LAN_REBOOT=0 wins over the GPU default' );

  my $k3s = run_probe( 'deploy', %base, LAN_DIST => 'k3s' );
  is( opts( $k3s, 'server' )->{distribution}, 'k3s', 'LAN_DIST=k3s asks for k3s' );

  my $host = run_probe( 'deploy', LAN_KUBECONFIG => $KUBECONFIG );
  is( opts( $host, 'server' )->{tls_san}, '192.0.2.11', 'without LAN_SERVER the host is the tls_san' );

  my %env = (
    LAN_TOKEN              => 'K10secret::server:token',
    LAN_VERSION            => 'v1.33.4+rke2r1',
    LAN_CLUSTER_CIDR       => '10.44.0.0/16',
    LAN_CILIUM_VERSION     => '1.20.2',
    LAN_CILIUM_CLI_VERSION => '0.20.0',
    LAN_HOSTNAME           => 'lan-server',
    LAN_DOMAIN             => 'lan.example',
    LAN_TIMEZONE           => 'Europe/Berlin',
  );
  my $full = run_probe( 'deploy', %base, %env );
  my $s    = opts( $full, 'server' );
  is( $s->{token},          $env{LAN_TOKEN},          'the token is handed over' );
  is( $s->{version},        $env{LAN_VERSION},        'the version is pinned' );
  is( $s->{cluster_cidr},   $env{LAN_CLUSTER_CIDR},   'the cluster_cidr is handed over' );
  is( $s->{cilium_version}, $env{LAN_CILIUM_VERSION}, 'the Cilium version is handed over' );
  is( $s->{cilium_cli_version}, $env{LAN_CILIUM_CLI_VERSION}, 'the Cilium CLI version is handed over' );
  is( $s->{hostname},       $env{LAN_HOSTNAME},       'the hostname is handed over' );
  is( $s->{domain},         $env{LAN_DOMAIN},         'the domain is handed over' );
  is( $s->{timezone},       $env{LAN_TIMEZONE},       'the timezone is handed over' );
};

subtest 'the agent options follow the environment' => sub {
  my %base = ( LAN_SERVER => '192.0.2.10', LAN_TOKEN => 'K10secret::server:token' );

  my $res = run_probe( 'join_agent', %base );
  is( $res->{exit}, 0, 'the join_agent task runs offline' )
    or diag( $res->{raw} . $res->{stderr} );

  my $agent = opts( $res, 'agent' );
  is( $agent->{distribution}, 'rke2', 'rke2 is the default distribution' );
  is( $agent->{gpu},         0,      'LAN_AGENT_GPU defaults to 0' );
  is( $agent->{reboot},      0,      'no GPU on the agent, no reboot' );
  is( $agent->{server}, 'https://192.0.2.10:9345', 'the agent joins the server on the rke2 port' );

  my $k3s = run_probe( 'join_agent', %base, LAN_DIST => 'k3s' );
  is( opts( $k3s, 'agent' )->{server}, 'https://192.0.2.10:6443', 'k3s joins on its own port' );

  my $url = run_probe( 'join_agent', %base, LAN_JOIN_URL => 'https://192.0.2.99:1234' );
  is( opts( $url, 'agent' )->{server}, 'https://192.0.2.99:1234', 'LAN_JOIN_URL overrides the join URL' );

  my $gpu = run_probe( 'join_agent', %base, LAN_AGENT_GPU => 1 );
  is( opts( $gpu, 'agent' )->{gpu},    1, 'LAN_AGENT_GPU=1 asks for a GPU on the agent' );
  is( opts( $gpu, 'agent' )->{reboot}, 1, 'a GPU on the agent reboots it' );

  my $named = run_probe( 'join_agent', %base, LAN_AGENT_HOSTNAME => 'lan-agent' );
  is( opts( $named, 'agent' )->{hostname}, 'lan-agent', 'the agent hostname is handed over' );

  my $no_server = run_probe( 'join_agent', LAN_TOKEN => 'K10secret::server:token' );
  isnt( $no_server->{exit}, 0, 'without LAN_SERVER the agent does not join' );
  like( $no_server->{data}{error} // '', qr/LAN_SERVER/, 'the file says which variable is missing' );
};

subtest 'cilium_upgrade needs a target version and a kubeconfig' => sub {
  my %base = ( LAN_SERVER => '192.0.2.10' );

  my $no_version = run_probe( 'cilium_upgrade', %base, LAN_KUBECONFIG => $KUBECONFIG );
  isnt( $no_version->{exit}, 0, 'without LAN_CILIUM_UPGRADE_TO the task refuses' );
  like( $no_version->{data}{error} // '', qr/LAN_CILIUM_UPGRADE_TO/, 'the file says which variable is missing' );

  my $missing = File::Spec->catfile( $TMP, 'missing-kubeconfig.yaml' );
  my $no_kubeconfig = run_probe( 'cilium_upgrade', %base,
    LAN_KUBECONFIG => $missing, LAN_CILIUM_UPGRADE_TO => '1.20.2' );
  isnt( $no_kubeconfig->{exit}, 0, 'without a kubeconfig the task refuses' );
  like( $no_kubeconfig->{data}{error} // '', qr/No kubeconfig/, 'the file says to run deploy first' );

  open my $fh, '>', $KUBECONFIG or die "cannot write $KUBECONFIG: $!\n";
  close $fh;

  my $up = run_probe( 'cilium_upgrade', %base, LAN_KUBECONFIG => $KUBECONFIG, LAN_CILIUM_UPGRADE_TO => '1.20.2' );
  is( $up->{exit}, 0, 'with both the task runs' ) or diag( $up->{raw} . $up->{stderr} );

  my $u = opts( $up, 'upgrade' );
  is( $u->{distribution}, 'rke2',       'the distribution is handed over' );
  is( $u->{kubeconfig},   $KUBECONFIG, 'the kubeconfig is handed over' );
  is( $u->{version},      '1.20.2',    'the target version is handed over' );
  is( $u->{wait},         1,           'the upgrade waits until ready' );
  ok( !exists $u->{k8s_service_host}, 'rke2 needs no k8s_service_host' );

  my $k3s = run_probe( 'cilium_upgrade', %base,
    LAN_DIST => 'k3s', LAN_KUBECONFIG => $KUBECONFIG, LAN_CILIUM_UPGRADE_TO => '1.20.2' );
  is( opts( $k3s, 'upgrade' )->{k8s_service_host}, '192.0.2.10', 'k3s needs the service host' );

  unlink $KUBECONFIG;
};

subtest 'the check task asks for the control points' => sub {
  unlink $KUBECONFIG;

  my $res = run_probe( 'check', LAN_SERVER => '192.0.2.10', LAN_KUBECONFIG => $KUBECONFIG );
  is( $res->{exit}, 0, 'the check task runs offline' )
    or diag( $res->{raw} . $res->{stderr} );

  my @cmds = @{ $res->{data}{cmds} // [] };
  my $all = join "\n", @cmds;

  like( $all, qr/systemctl is-active rke2-server/,   'the server service is asked for' );
  like( $all, qr{/etc/rancher/rke2/config\.yaml},   'the config.yaml is dumped' );
  like( $all, qr/redacted/,                         'the join token is redacted in the dump' );
  like( $all, qr/sshd -T/,                           'the sshd subsystem is asked for (SFTP-less rehearsal)' );
  like( $all, qr/nvidia-smi/,                       'the GPU is asked for' );
  like( $all, qr{config-v3\.toml\.d/99-nvidia\.toml}, 'the containerd drop-in is asked for' );

  my $k3s = run_probe( 'check', LAN_DIST => 'k3s', LAN_SERVER => '192.0.2.10', LAN_KUBECONFIG => $KUBECONFIG );
  my $k3s_all = join "\n", @{ $k3s->{data}{cmds} // [] };
  like( $k3s_all, qr/systemctl is-active k3s/,       'k3s has its own service' );
  like( $k3s_all, qr{/etc/rancher/k3s/config\.yaml}, 'k3s has its own config' );
};

# --- nothing Hetzner-specific ---------------------------------------------

subtest 'the LAN rig has nothing Hetzner-specific left' => sub {
  open my $fh, '<', $REXFILE or die "cannot read $REXFILE: $!\n";
  my @lines = <$fh>;
  close $fh;

  my $source = join "\n", @lines;
  my $code   = join "\n", grep { !/^\s*#/ } @lines;

  unlike( $code,   qr/hetzner/i,                 'no Hetzner in the code' );
  unlike( $source, qr/hetzner\.(?:de|com|eu)/i, 'no Hetzner host names' );
  unlike( $source, qr/\b(?:nbg|hel|fsn|cpx|dra)\d+\b/i, 'no Hetzner location codes' );

  my @addresses;
  while ( $source =~ /\b(\d{1,3}(?:\.\d{1,3}){3})(\/\d+)?/g ) {
    push @addresses, $1 unless $2;    # a CIDR is a network, not a host
  }
  my @real = grep { !/\A192\.0\.2\./ } @addresses;
  is_deeply( \@real, [], 'every host address is a 192.0.2.x placeholder' );

  unlike( $code, qr/OpenSSH/,       'the connection is not OpenSSH' );
  unlike( $code, qr/\bupload\b/,    'nothing is uploaded (no SFTP transfer)' );
  unlike( $code, qr/\bfile\s+['"]/, 'no file is fetched (no SFTP transfer)' );
  like( $code, qr/set connection\s*=>\s*'LibSSH'/, 'the connection is LibSSH' );
  like( $code, qr/sshd -T/,         'the sshd subsystem is probed instead of used' );
};

# --- the real CLI ---------------------------------------------------------

subtest 'the rex CLI lists the tasks of the Rexfile' => sub {
  my $rex = find_rex();
  plan skip_all => 'no rex binary found -- set REX_BIN to the one to use' unless $rex;

  my $lib = File::Spec->catdir( $ROOT, 'lib' );
  $lib = File::Spec->catdir( $ROOT, 'blib', 'lib' ) unless -d $lib;

  local %ENV = (
    %ENV,
    PERL5LIB => join( ':', grep { length } $lib, ( $ENV{PERL5LIB} // '' ) ),
  );

  my $errfile = File::Spec->catfile( $TMP, 'rex.err' );
  open my $olderr, '>&', \*STDERR or die "cannot dup STDERR: $!\n";
  open STDERR, '>', $errfile      or die "cannot write $errfile: $!\n";

  my ( $out, $exit );
  my $ok = eval { ( $out, $exit ) = run_in_root( $rex, '-f', 'eg/lan.Rexfile', '-T' ); 1 };
  my $err = $@;

  open STDERR, '>&', $olderr or die "cannot restore STDERR: $!\n";
  die $err unless $ok;

  my %listed;
  for my $line ( split /\n/, ( $out // '' ) ) {
    $line =~ s/\e\[[0-9;]*m//g;    # the CLI colours its task list
    next unless $line =~ /^ (\S+)\s{2,}(.*)$/;
    $listed{$1} = $2;
  }

  plan skip_all => 'the rex CLI prints its task list in another format' unless %listed;

  is( $exit, 0, 'rex -T runs' );
  for my $task (@ALL_TASKS) {
    ok( exists $listed{$task}, "the CLI lists $task" );
  }
};

# --- what only a live run can prove ---------------------------------------

subtest 'the live run' => sub {
  plan skip_all => 'needs the LAN test machine (GTX-class consumer GPU) -- '
    .'no such machine in the fleet; the checklist stands in eg/lan.RUNBOOK.md';
};

done_testing;
