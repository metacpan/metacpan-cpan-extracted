use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests for the install_method option, the installed-version check and
# the service wait, server and agent, rke2 and k3s alike.
#
# - install_method: 'script' (default) keeps the curl | sh lines unchanged;
#   'artifact' needs a version and dies without one, before touching the host.
# - uname -m -> GOARCH mapping; artifact names/URLs per distribution and arch.
# - checksum lookup/compare as pure functions; a mismatch dies.
# - fetch_artifacts downloads on the host (curl, no upload) and dies on a
#   failed download or a mismatching checksum.
# - verify_installed_version: pinned version vs `<bin> --version`.
# - wait_for_service: polls is-active; failed/timeout die with the journal.
# (Methods of Rex::Rancher::Distribution, which Server and Agent share.)
#
# `run` and `sleep` never reach a host: `run` is replaced in
# Rex::Commands::Run, which Server and Agent import and Rex::Rancher::Distribution
# calls. This proves decision logic and command strings, not a deploy.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::Distribution;

my $D = 'Rex::Rancher::Distribution';
sub dist { $D->new_for(@_) }
sub agent { $D->new_for( $_[0], role => 'agent' ) }

# Scripted fake remote: @script holds [ qr/cmd/, $output, $exit ] handlers,
# first match wins; unmatched commands succeed silently. All commands recorded.
my ( @script, @cmds );
my $fake = sub {
  my ( $cmd ) = @_;
  push @cmds, $cmd;
  for my $h (@script) {
    my ( $re, $out, $exit ) = @{$h};
    next unless $cmd =~ $re;
    $out = $out->() if ref $out eq 'CODE';
    $? = ( $exit // 0 ) << 8;
    return $out;
  }
  $? = 0;
  return '';
};
{
  no warnings 'redefine';
  *Rex::Commands::Run::run   = $fake;
  *Rex::Rancher::Server::run = $fake;
  *Rex::Rancher::Agent::run  = $fake;
}

sub reset_remote { @script = @_; @cmds = () }

sub dies_like (&$$) {
  my ( $code, $re, $name ) = @_;
  eval { $code->(); 1 } and return fail("$name: did not die");
  like( $@, $re, $name );
}

# ---- install_method --------------------------------------------------------

subtest 'resolve_install_method' => sub {
  is( $D->resolve_install_method(undef, undef), 'script', 'default is script' );
  is( $D->resolve_install_method('script', undef), 'script', 'script without version' );
  is( $D->resolve_install_method('artifact', 'v1.30.4+rke2r1'), 'artifact', 'artifact with version' );
  dies_like { $D->resolve_install_method('artifact', undef) }
    qr/install_method 'artifact' requires a version/, 'artifact without version dies';
  dies_like { $D->resolve_install_method('rpm', 'v1') }
    qr/Unknown install_method: rpm/, 'unknown method dies';
};

subtest 'artifact without version dies before touching the host' => sub {
  for my $dist (qw( rke2 k3s )) {
    reset_remote();
    dies_like { install_server( distribution => $dist, install_method => 'artifact' ) }
      qr/requires a version/, "$dist server";
    is( scalar @cmds, 0, "$dist server: no remote command ran" );

    reset_remote();
    dies_like {
      install_agent( distribution => $dist, server => 'https://cp1:9345', token => 't',
        install_method => 'artifact' )
    } qr/requires a version/, "$dist agent";
    is( scalar @cmds, 0, "$dist agent: no remote command ran" );
  }
};

subtest 'script method: installer lines unchanged' => sub {
  is( dist('rke2')->script_install_cmd( undef, undef ),
    'curl -sfL https://get.rke2.io | sh -', 'rke2 server' );
  is( agent('rke2')->script_install_cmd( 'https://cp1:9345', undef ),
    'curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -', 'rke2 agent' );
  is( agent('k3s')->script_install_cmd( 'https://cp1:6443', undef ),
    'curl -sfL https://get.k3s.io | K3S_URL=https://cp1:6443 INSTALL_K3S_SKIP_START=true sh -s - agent',
    'k3s agent: the script does not start it (bounded start follows)' );
  my $kp = dist('k3s');
  is( $kp->script_install_cmd( undef, undef ),
    'curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true sh -s - server --write-kubeconfig-mode=644',
    'k3s server: the script does not start it (bounded start follows)' );
  is( $kp->script_install_cmd( 'https://cp1:6443', 'v1.30.4+k3s1' ),
    'curl -sfL https://get.k3s.io | K3S_URL=https://cp1:6443 INSTALL_K3S_VERSION=v1.30.4+k3s1'
      . ' INSTALL_K3S_SKIP_START=true sh -s - server --write-kubeconfig-mode=644',
    'k3s server HA join: same' );
};

# ---- arch ------------------------------------------------------------------

subtest 'goarch' => sub {
  my $g = sub { $D->goarch(@_) };
  is( $g->("x86_64\n"), 'amd64', 'x86_64 (with newline)' );
  is( $g->('amd64'),    'amd64', 'amd64' );
  is( $g->("aarch64\n"), 'arm64', 'aarch64' );
  is( $g->('arm64'),    'arm64', 'arm64' );
  dies_like { $g->('armv7l') } qr/Unsupported node architecture 'armv7l'/, 'armv7l dies';
  dies_like { $g->('s390x') }  qr/amd64 and arm64 only/, 's390x dies';
  dies_like { $g->(undef) }    qr/Unsupported node architecture ''/, 'empty dies';
};

# ---- artifact spec ---------------------------------------------------------

subtest 'artifact_spec' => sub {
  my $spec = sub { my ( $dist, @a ) = @_; dist($dist)->artifact_spec(@a) };
  my %want = (
    'rke2 amd64' => [ 'rke2.linux-amd64.tar.gz', 'https://github.com/rancher/rke2/releases/download/v1.30.4%2Brke2r1', '/tmp/rke2-artifacts', 'https://get.rke2.io', 'v1.30.4+rke2r1' ],
    'rke2 arm64' => [ 'rke2.linux-arm64.tar.gz', 'https://github.com/rancher/rke2/releases/download/v1.30.4%2Brke2r1', '/tmp/rke2-artifacts', 'https://get.rke2.io', 'v1.30.4+rke2r1' ],
    'k3s amd64'  => [ 'k3s',                     'https://github.com/k3s-io/k3s/releases/download/v1.30.4%2Bk3s1',    '/tmp/k3s-artifacts',  'https://get.k3s.io',  'v1.30.4+k3s1' ],
    'k3s arm64'  => [ 'k3s-arm64',               'https://github.com/k3s-io/k3s/releases/download/v1.30.4%2Bk3s1',    '/tmp/k3s-artifacts',  'https://get.k3s.io',  'v1.30.4+k3s1' ],
  );
  for my $k ( sort keys %want ) {
    my ( $dist, $arch ) = split / /, $k;
    my ( $asset, $base, $dir, $script_url, $ver ) = @{ $want{$k} };
    my $s = $spec->( $dist, $arch, $ver );
    is( $s->{asset},      $asset,                        "$k: asset" );
    is( $s->{asset_url},  "$base/$asset",                "$k: asset url, + encoded" );
    is( $s->{sums},       "sha256sum-$arch.txt",         "$k: sums file" );
    is( $s->{sums_url},   "$base/sha256sum-$arch.txt",   "$k: sums url" );
    is( $s->{dir},        $dir,                          "$k: dir" );
    is( $s->{script},     "$dir/install.sh",             "$k: script path" );
    is( $s->{script_url}, $script_url,                   "$k: script url" );
  }
  dies_like { $spec->( 'rke2', 'amd64', undef ) } qr/requires a version/, 'no version';
  dies_like { $spec->( 'rke2', 'amd64', 'v1; rm -rf /' ) } qr/Invalid version/, 'shell junk in version';
  dies_like { $spec->( 'microk8s', 'amd64', 'v1' ) } qr/Unknown distribution/, 'unknown distribution';
};

# ---- checksum --------------------------------------------------------------

my $H1 = 'a' x 64;
my $H2 = 'b' x 64;
my $H3 = 'c' x 64;
my $H4 = 'd' x 64;

subtest 'expected_sha256' => sub {
  my $e = sub { $D->expected_sha256(@_) };
  my $k3s_sums = "$H1  k3s-airgap-images-arm64.tar.gz\n$H2  k3s-arm64\n$H3  k3s\n";
  is( $e->( $k3s_sums, 'k3s' ),       $H3, 'k3s: exact name, not the airgap line' );
  is( $e->( $k3s_sums, 'k3s-arm64' ), $H2, 'k3s-arm64' );
  my $rke2_sums = "$H1  rke2.linux-arm64\n$H4  rke2.linux-arm64.tar.gz\n";
  is( $e->( $rke2_sums, 'rke2.linux-arm64.tar.gz' ), $H4, 'rke2 tarball, not the bare binary' );
  is( $e->( "$H2 *k3s\n", 'k3s' ), $H2, 'binary-mode marker' );
  is( $e->( uc("$H1") . "  k3s\n", 'k3s' ), $H1, 'upper-case hex normalised' );
  is( $e->( $k3s_sums, 'k3s-s390x' ), undef, 'absent asset: undef' );
  is( $e->( undef, 'k3s' ), undef, 'no text: undef' );
};

subtest 'sha256_of / verify_sha256' => sub {
  is( $D->sha256_of("$H1  /tmp/k3s-artifacts/k3s\n"), $H1, 'sha256sum output parsed' );
  is( $D->sha256_of("sha256sum: x: No such file\n"), undef, 'error output: undef' );
  my $v = sub { $D->verify_sha256(@_) };
  ok( $v->( $H1, $H1, 'k3s' ), 'match' );
  dies_like { $v->( $H1, $H2, 'k3s' ) } qr/Checksum mismatch for k3s: expected $H1, got $H2/, 'mismatch dies with both';
  dies_like { $v->( undef, $H2, 'k3s' ) } qr/No checksum for k3s/, 'missing expected dies';
  dies_like { $v->( $H1, undef, 'k3s' ) } qr/Could not compute sha256/, 'missing actual dies';
};

# ---- fetch_artifacts against the fake remote ------------------------------

sub fetch_script {
  my ( %o ) = @_;
  return (
    [ qr/^uname -m$/,              $o{uname} // "aarch64\n" ],
    $o{fail} ? [ qr/^curl .*\Q$o{fail}\E/, "curl: (22) 404", 22 ] : (),
    [ qr/^cat '.*sha256sum-/,      $o{sums} ],
    [ qr/^sha256sum /,             $o{actual} ],
  );
}

subtest 'fetch_artifacts: k3s arm64 happy path' => sub {
  reset_remote( fetch_script( sums => "$H1  k3s-airgap-images-arm64.tar\n$H2  k3s-arm64\n",
    actual => "$H2  /tmp/k3s-artifacts/k3s-arm64\n" ) );
  my $s = dist('k3s')->fetch_artifacts( 'v1.30.4+k3s1' );
  is( $s->{asset}, 'k3s-arm64', 'arch from uname -m on the host' );
  is( $cmds[1], "rm -rf '/tmp/k3s-artifacts' && mkdir -p '/tmp/k3s-artifacts'", 'dir emptied first' );
  my @curl = grep { /^curl / } @cmds;
  is( scalar @curl, 3, 'three downloads, all on the host via curl' );
  like( $curl[0], qr{-o '/tmp/k3s-artifacts/install\.sh' 'https://get\.k3s\.io'}, 'install script' );
  like( $curl[1], qr{sha256sum-arm64\.txt'}, 'checksum file' );
  like( $curl[2], qr{--progress-bar -o '/tmp/k3s-artifacts/k3s-arm64' 'https://github\.com/k3s-io/k3s/releases/download/v1\.30\.4%2Bk3s1/k3s-arm64'},
    'artifact with progress bar' );
};

subtest 'fetch_artifacts: checksum mismatch dies' => sub {
  reset_remote( fetch_script( uname => "x86_64\n", sums => "$H1  rke2.linux-amd64.tar.gz\n",
    actual => "$H2  /tmp/rke2-artifacts/rke2.linux-amd64.tar.gz\n" ) );
  dies_like { dist('rke2')->fetch_artifacts( 'v1.30.4+rke2r1' ) }
    qr/Checksum mismatch for rke2\.linux-amd64\.tar\.gz: expected $H1, got $H2/, 'loud mismatch';
};

subtest 'fetch_artifacts: asset missing from sums dies' => sub {
  reset_remote( fetch_script( sums => "$H1  something-else\n", actual => "$H2  x\n" ) );
  dies_like { dist('rke2')->fetch_artifacts( 'v1.30.4+rke2r1' ) }
    qr/No checksum for rke2\.linux-arm64\.tar\.gz/, 'no silent pass';
};

subtest 'fetch_artifacts: failed download dies with URL and arch hint' => sub {
  reset_remote( fetch_script( fail => 'rke2.linux-arm64.tar.gz' ) );
  dies_like { dist('rke2')->fetch_artifacts( 'v9.9.9+rke2r1' ) }
    qr{Download failed: https://github\.com/rancher/rke2/releases/download/v9\.9\.9%2Brke2r1/rke2\.linux-arm64\.tar\.gz\n.*no build for 'arm64'}s,
    'dies naming URL and arch';
  ok( !grep( /^sha256sum /, @cmds ), 'no checksum step after a failed download' );
};

subtest 'fetch_artifacts: unsupported arch dies before downloading' => sub {
  reset_remote( fetch_script( uname => "armv7l\n" ) );
  dies_like { dist('k3s')->fetch_artifacts( 'v1.30.4+k3s1' ) }
    qr/Unsupported node architecture 'armv7l'/, 'dies';
  ok( !grep( /^curl /, @cmds ), 'nothing downloaded' );
};

# ---- artifact install commands ---------------------------------------------

subtest 'artifact install commands' => sub {
  my $rs = dist('rke2')->artifact_spec( 'arm64', 'v1.30.4+rke2r1' );
  is_deeply( [ dist('rke2')->artifact_install_cmds( $rs, undef, 'v1.30.4+rke2r1' ) ], [
    'INSTALL_RKE2_ARTIFACT_PATH=/tmp/rke2-artifacts INSTALL_RKE2_VERSION=v1.30.4+rke2r1 sh /tmp/rke2-artifacts/install.sh',
    ], 'rke2 server' );
  is_deeply( [ agent('rke2')->artifact_install_cmds( $rs, 'https://cp1:9345', 'v1.30.4+rke2r1' ) ], [
    'INSTALL_RKE2_ARTIFACT_PATH=/tmp/rke2-artifacts INSTALL_RKE2_TYPE=agent INSTALL_RKE2_VERSION=v1.30.4+rke2r1 sh /tmp/rke2-artifacts/install.sh',
    ], 'rke2 agent' );

  my $ks = dist('k3s')->artifact_spec( 'arm64', 'v1.30.4+k3s1' );
  my $place = "install -m 0755 -o root -g root '/tmp/k3s-artifacts/k3s-arm64' /usr/local/bin/.k3s.rex-new"
    . ' && mv -f /usr/local/bin/.k3s.rex-new /usr/local/bin/k3s';
  is_deeply( [ dist('k3s')->artifact_install_cmds( $ks, undef, 'v1.30.4+k3s1' ) ], [
    $place,
    'INSTALL_K3S_SKIP_DOWNLOAD=binary INSTALL_K3S_BIN_DIR=/usr/local/bin INSTALL_K3S_VERSION=v1.30.4+k3s1'
      . ' INSTALL_K3S_SKIP_START=true sh /tmp/k3s-artifacts/install.sh server --write-kubeconfig-mode=644',
    ], 'k3s server: binary placed atomically as /usr/local/bin/k3s, then the script, which does not start it' );
  is_deeply( [ agent('k3s')->artifact_install_cmds( $ks, 'https://cp1:6443', 'v1.30.4+k3s1' ) ], [
    $place,
    'K3S_URL=https://cp1:6443 INSTALL_K3S_SKIP_DOWNLOAD=binary INSTALL_K3S_BIN_DIR=/usr/local/bin'
      . ' INSTALL_K3S_VERSION=v1.30.4+k3s1 INSTALL_K3S_SKIP_START=true sh /tmp/k3s-artifacts/install.sh agent',
    ], 'k3s agent: same placement, the script does not start it' );
  for my $c (
    agent('rke2')->artifact_install_cmds( $rs, 'https://cp1:9345', 'v1' ),
    agent('k3s')->artifact_install_cmds( $ks, 'https://cp1:6443', 'v1' ),
  ) {
    unlike( $c, qr/TOKEN/, 'no token on an artifact installer line' );
    unlike( $c, qr/curl/,  'artifact installer line downloads nothing' );
  }
};

# ---- installed version -----------------------------------------------------

subtest 'parse_version_output / same_version' => sub {
  my $p = sub { $D->parse_version_output(@_) };
  is( $p->("rke2 version v1.30.4+rke2r1 (abc123)\ngo version go1.22.5 X:boringcrypto\n"),
    'v1.30.4+rke2r1', 'rke2' );
  is( $p->("k3s version v1.30.4+k3s1 (98262b5d)\ngo version go1.22.5\n"), 'v1.30.4+k3s1', 'k3s' );
  # k68: the first word is the name it was called by; through /proc/PID/exe
  # that is "exe". Measured on the v1.36.4 release binaries.
  is( $p->("exe version v1.36.4+rke2r1 (7479a59cdd2c8ce0b8871699a24daa4b7c28cc64)\n"
    . "go version go1.26.7-X:boringcrypto\n"), 'v1.36.4+rke2r1', 'rke2 through /proc/PID/exe' );
  is( $p->("exe version v1.36.4+k3s1 (4dedb15b)\ngo version go1.26.7\n"), 'v1.36.4+k3s1',
    'k3s through /proc/PID/exe' );
  is( $p->("go version go1.26.7\n"), undef, 'the go line alone: undef' );
  is( $p->("bash: rke2: command not found\n"), undef, 'not installed: undef' );
  is( $p->("sh: 1: /proc/123/exe: not found\n"), undef, 'no such process: undef' );
  is( $p->("sh: 1: /proc/123/exe: Permission denied\n"), undef, 'permission denied: undef' );
  my $s = sub { $D->same_version(@_) };
  ok( $s->( 'v1.30.4+rke2r1', 'v1.30.4+rke2r1' ), 'equal' );
  ok( $s->( '1.30.4+rke2r1', 'v1.30.4+rke2r1' ), 'leading v optional' );
  ok( !$s->( 'v1.30.4+rke2r1', 'v1.29.9+rke2r1' ), 'different' );
  ok( !$s->( 'v1.30.4+rke2r1', 'v1.30.4+rke2r2' ), 'release suffix counts' );
};

subtest 'verify_installed_version' => sub {
  reset_remote();
  ok( dist('rke2')->verify_installed_version(undef), 'unpinned: passes' );
  is( scalar @cmds, 0, 'unpinned: binary not even asked' );

  for my $dist (qw( rke2 k3s )) {
    my $want = $dist eq 'k3s' ? 'v1.30.4+k3s1' : 'v1.30.4+rke2r1';
    my $old  = $dist eq 'k3s' ? 'v1.29.9+k3s1' : 'v1.29.9+rke2r1';

    reset_remote( [ qr/^$dist --version/, "$dist version $want (abc)\n" ] );
    ok( dist($dist)->verify_installed_version($want), "$dist: match" );
    is( $cmds[0], "$dist --version 2>&1", "$dist: asks the binary" );

    reset_remote( [ qr/^$dist --version/, "$dist version $old (abc)\n" ] );
    dies_like { dist($dist)->verify_installed_version($want) }
      qr/Installed $dist version is \Q$old\E, expected \Q$want\E/, "$dist: stale binary dies";

    reset_remote( [ qr/^$dist --version/, "sh: $dist: not found\n", 127 ] );
    dies_like { dist($dist)->verify_installed_version($want) }
      qr/Could not determine installed $dist version.*not found/s, "$dist: missing binary dies";
  }
};

# ---- service wait ----------------------------------------------------------

my $JOURNAL = "Sep 24 rke2[123]: level=fatal msg=\"bootstrap data already found\"\n";

subtest 'wait_for_service: active' => sub {
  my @states = ( "activating\n", "activating\n", "active\n" );
  reset_remote( [ qr/^systemctl is-active rke2-server$/, sub { shift @states }, 3 ] );
  ok( dist('rke2')->wait_for_service( attempts => 5, interval => 0 ),
    'returns once active' );
  is( scalar( grep { /is-active/ } @cmds ), 3, 'polled until active' );
  ok( !grep( /journalctl/, @cmds ), 'no journal on success' );
};

subtest 'wait_for_service: failed dies with journal' => sub {
  reset_remote(
    [ qr/^systemctl is-active/, "failed\n", 3 ],
    [ qr/^journalctl -u k3s-agent\.service -n 50 --no-pager/, $JOURNAL ],
  );
  dies_like { agent('k3s')->wait_for_service( attempts => 5, interval => 0 ) }
    qr/k3s-agent\.service is failed\n--- journalctl -u k3s-agent\.service -n 50 ---\n.*bootstrap data already found/s,
    'die text carries state and journal';
  is( scalar( grep { /is-active/ } @cmds ), 1, 'failed stops polling at once' );
};

subtest 'wait_for_service: timeout dies with last state and journal' => sub {
  reset_remote(
    [ qr/^systemctl is-active/, "activating\n", 3 ],
    [ qr/^journalctl/, $JOURNAL ],
  );
  dies_like { dist('rke2')->wait_for_service( attempts => 3, interval => 0 ) }
    qr/rke2-server did not become active within 0s \(last state: activating\)\n.*bootstrap data/s,
    'timeout die text';
  is( scalar( grep { /is-active/ } @cmds ), 3, 'polled every attempt' );
};

subtest 'wait_for_service: empty journal still reported' => sub {
  reset_remote( [ qr/^systemctl is-active/, "failed\n", 3 ], [ qr/^journalctl/, '' ] );
  dies_like { agent('rke2')->wait_for_service( attempts => 1, interval => 0 ) }
    qr/\(no journal output\)/, 'placeholder instead of silence';
};

subtest 'wait_for_service: hint under the reason (k44)' => sub {
  my $hint = 'It joins the cluster via https://cp1:9345 -- check that this node can reach that address';
  reset_remote( [ qr/^systemctl is-active/, "failed\n", 3 ], [ qr/^journalctl/, $JOURNAL ] );
  dies_like { agent('rke2')->wait_for_service( attempts => 2, interval => 0,
    hint => $hint ) }
    qr/rke2-agent\.service is failed\n\Q$hint\E\n--- journalctl -u rke2-agent\.service -n 50 ---\n.*bootstrap/s,
    'failed: reason, hint, journal';
  reset_remote( [ qr/^systemctl is-active/, "activating\n", 3 ], [ qr/^journalctl/, $JOURNAL ] );
  dies_like { agent('k3s')->wait_for_service( attempts => 2, interval => 0,
    hint => $hint ) }
    qr/\(last state: activating\)\n\Q$hint\E\n--- journalctl/s, 'timeout: reason, hint, journal';
};

done_testing;
