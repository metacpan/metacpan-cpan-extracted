use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# The mode of the kubeconfig a server writes on the node
# (/etc/rancher/k3s/k3s.yaml, /etc/rancher/rke2/rke2.yaml). It holds the
# cluster admin's client certificate and key, and RKE2 and K3s write it 0600
# on their own.
#
# - No installer line asks for another mode: the K3s ones carried
#   --write-kubeconfig-mode=644, which made every local account on a server
#   node cluster admin.
# - Without kubeconfig_mode config.yaml carries no write-kubeconfig-mode, on
#   rke2 and k3s alike: the distribution's own 0600 applies.
# - kubeconfig_mode is the way to another mode, the same on both: written as
#   write-kubeconfig-mode to config.yaml, as a YAML string (an unquoted 0644
#   is the number 420 to the YAML reader of either distribution).
# - Anything but a string of a zero and three octal digits dies before the
#   host is touched; a number never passes (the Perl literal 0640 is 416).
#
# run and file are faked. This proves the command strings and config.yaml,
# not the mode a real rke2/k3s gives the file -- only a live run does.
# -----------------------------------------------------------------------------

use YAML::PP;
use Rex::Rancher::Server;
use Rex::Rancher::Distribution;
use Rex::Rancher::Options;

my $D = 'Rex::Rancher::Distribution';

my ( @log, %written );
{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    # A fresh host: no service, no binary before the install, no state.
    if ( $cmd =~ /^systemctl is-active --quiet / ) { $? = 3 << 8; return '' }
    return "active\n"               if $cmd =~ /^systemctl is-active /;
    return "MainPID=0\n"            if $cmd =~ /^systemctl show -p MainPID /;
    return "/usr/local/bin/rke2\n"  if $cmd =~ /^command -v rke2/;
    return "yes\n"                  if $cmd =~ /^test -f /;
    if ( $cmd =~ /^(?:test -[ed] |cat |curl -fsSL -o \/dev\/null |(?:rke2|k3s) --version)/ ) {
      $? = 1 << 8;
      return '';
    }
    return 'G' x 48 if $cmd =~ m{/dev/urandom};
    return '';
  };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  # One sub for both: Rex::Exporter aliases the whole glob.
  my $file = sub { my ( $p, %o ) = @_; push @log, "file $p"; $written{$p} = $o{content} if exists $o{content} };
  *Rex::Commands::File::file  = $file;
  *Rex::Rancher::Server::file = $file;
  *Rex::Commands::File::get_tmp_file_name = sub { '/tmp/.rex.tmp' };
  *Rex::Logger::info = sub { };
}

sub reset_host { @log = (); %written = () }

sub cfg { my ( $d, @rest ) = @_; Rex::Rancher::Server::_build_server_config( $D->new_for($d), @rest ) }
#  ($distribution, $token, $server, $tls_san, $node_labels, $cilium, $node_name,
#   $disable, $cluster_cidr, $kubeconfig_mode)

my %VERSION = ( rke2 => 'v1.30.4+rke2r1', k3s => 'v1.30.4+k3s1' );

# ---- the installer lines ----------------------------------------------------

subtest 'no installer line sets the kubeconfig mode' => sub {
  for my $dist (qw( rke2 k3s )) {
    my $d    = $D->new_for($dist);
    my $spec = $d->artifact_spec( 'amd64', $VERSION{$dist} );
    my %line = (
      'script, first server' => $d->script_install_cmd( undef, undef ),
      'script, HA join'      => $d->script_install_cmd( 'https://cp1:6443', $VERSION{$dist} ),
      'artifact'             => join( "\n", $d->artifact_install_cmds( $spec, undef, $VERSION{$dist} ) ),
      'artifact, HA join'    => join( "\n", $d->artifact_install_cmds( $spec, 'https://cp1:6443', $VERSION{$dist} ) ),
    );
    unlike( $line{$_}, qr/kubeconfig-mode/, "$dist $_" ) for sort keys %line;
  }
};

subtest 'k3s server lines end with the role' => sub {
  my $k3s = $D->new_for('k3s');
  is( $k3s->script_install_cmd( undef, undef ),
    'curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true sh -s - server', 'script' );
  my ( undef, $cmd ) = $k3s->artifact_install_cmds( $k3s->artifact_spec( 'amd64', $VERSION{k3s} ), undef, $VERSION{k3s} );
  like( $cmd, qr{ sh /tmp/k3s-artifacts/install\.sh server\z}, 'artifact' );
};

# ---- the option check -------------------------------------------------------

subtest 'check_kubeconfig_mode' => sub {
  my $check = sub { Rex::Rancher::Options->check_kubeconfig_mode(@_) };
  is( scalar $check->(undef), undef, 'undef: none, the distribution default' );
  is( $check->($_), $_, "'$_' passes" ) for qw( 0644 0640 0600 0400 );
  # Numbers never pass: 0640 as a Perl literal is 416, and 0416 would be
  # readable and writable by everyone.
  for my $bad ( 0640, 0644, 640, '644', '', 'rw-r--r--', '0688', '064', '06444', '4644', '0o644',
    '0x1a4', 'u+r', "0644\n", ' 0644', [ '0644' ] ) {
    my $shown = ref $bad ? 'an array reference' : "'$bad'";
    $shown =~ s/\n/\\n/;
    ok( !eval { $check->($bad); 1 }, "$shown dies" );
    like( $@, qr/\Akubeconfig_mode must be an octal file mode as a string such as '0640', got /,
      '  with the way out' );
  }
};

# ---- config.yaml ------------------------------------------------------------

for my $dist (qw( rke2 k3s )) {
  subtest "$dist: config.yaml" => sub {
    my $c = cfg( $dist, 'tok', undef, undef, undef, 1 );
    ok( !exists $c->{'write-kubeconfig-mode'}, 'no write-kubeconfig-mode by default' );

    $c = cfg( $dist, 'tok', undef, undef, undef, 1, undef, undef, undef, '0644' );
    is( $c->{'write-kubeconfig-mode'}, '0644', 'kubeconfig_mode written as write-kubeconfig-mode' );
    like( YAML::PP->new( boolean => 'JSON::PP' )->dump_string($c),
      qr/^write-kubeconfig-mode: '0644'$/m, 'a quoted YAML string, not the number 420' );
  };

  subtest "$dist: install_server" => sub {
    my $file = "/etc/rancher/$dist/config.yaml";

    reset_host();
    ok( eval { install_server( distribution => $dist, token => 't' ); 1 }, 'default: installs' ) or diag $@;
    ok( defined $written{$file}, 'config.yaml written' );
    unlike( $written{$file} // '', qr/kubeconfig-mode/, 'config.yaml: no write-kubeconfig-mode' );
    is_deeply( [ grep { /kubeconfig-mode/ } @log ], [], 'no command sets one either' );
    ok( ( grep { /get\.\Q$dist\E\.io/ } @log ), 'installer ran' );

    reset_host();
    ok( eval { install_server( distribution => $dist, token => 't', kubeconfig_mode => '0644' ); 1 },
      'kubeconfig_mode 0644: installs' ) or diag $@;
    is( YAML::PP->new->load_string( $written{$file} // '' )->{'write-kubeconfig-mode'}, '0644',
      'config.yaml: write-kubeconfig-mode 0644' );
    like( $written{$file} // '', qr/^write-kubeconfig-mode: '0644'$/m, 'as a quoted string' );
    is_deeply( [ grep { /kubeconfig-mode/ } @log ], [], 'still not on a command line' );

    reset_host();
    ok( !eval { install_server( distribution => $dist, token => 't', kubeconfig_mode => 'world' ); 1 },
      'an invalid kubeconfig_mode dies' );
    like( $@, qr/\Akubeconfig_mode must be an octal file mode/, 'naming the option' );
    is( scalar @log, 0, 'before any command ran on the host' );
  };
}

subtest 'preflight_server hands the checked mode on' => sub {
  reset_host();
  is( Rex::Rancher::Server::preflight_server( distribution => 'k3s', kubeconfig_mode => '0640' )->{kubeconfig_mode},
    '0640', 'the mode' );
  reset_host();
  is( Rex::Rancher::Server::preflight_server( distribution => 'k3s' )->{kubeconfig_mode}, undef, 'none without it' );
};

done_testing;
