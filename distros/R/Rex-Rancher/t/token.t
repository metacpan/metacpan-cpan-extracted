use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests for cluster-token handling.
#
# 1. install_server without a token must reuse the token a live control plane
#    is sealed with (/var/lib/rancher/{rke2,k3s}/server/token) instead of
#    minting a new one: the datastore key derives from it, and a rotated token
#    makes the next service restart die with "bootstrap data already found and
#    encrypted with different token". A passed token always wins; only a fresh
#    server (no file) gets a generated one.
# 2. The token never appears on an installer command line (visible in ps); it
#    reaches the node through config.yaml only, for server and agent, rke2 and
#    k3s alike.
#
# `run` is replaced in Rex::Rancher::Server so no remote host is involved.
# This proves the decision logic and the command strings, not a deploy.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;

my $TOKEN = 'K10deadbeef::server:s3cr3t-token-value-0123456789';

# Fake remote: %files maps path => content; every command is recorded.
my ( %files, @cmds );
{
  no warnings 'redefine';
  *Rex::Rancher::Server::run = sub {
    my ( $cmd ) = @_;
    push @cmds, $cmd;
    if ( $cmd =~ m{^cat (\S+)} ) {
      if ( exists $files{$1} ) { $? = 0; return $files{$1} }
      $? = 1 << 8;
      return '';
    }
    if ( $cmd =~ m{/dev/urandom} ) { $? = 0; return 'G' x 48 }
    $? = 0;
    return '';
  };
}

sub resolve {
  my ( $dist, $given ) = @_;
  @cmds = ();
  Rex::Rancher::Server::_resolve_token( Rex::Rancher::Server::_paths($dist), $given );
}

for my $dist (qw( rke2 k3s )) {
  my $path = "/var/lib/rancher/$dist/server/token";

  subtest "$dist: existing server token is reused" => sub {
    %files = ( $path => $TOKEN."\n" );
    is( resolve($dist), $TOKEN, 'on-disk token returned, trailing newline trimmed' );
    ok( !grep( m{urandom}, @cmds ), 'no new token generated' );
    is( $cmds[0], "cat $path 2>/dev/null", "reads $path over run/cat (no SFTP)" );
  };

  subtest "$dist: fresh server generates a token" => sub {
    %files = ();
    is( resolve($dist), 'G' x 48, 'generated token when no file exists' );
    ok( grep( m{urandom}, @cmds ), 'generator ran' );
  };

  subtest "$dist: empty token file counts as none" => sub {
    %files = ( $path => "\n" );
    is( resolve($dist), 'G' x 48, 'whitespace-only file falls back to generation' );
  };

  subtest "$dist: passed token wins" => sub {
    %files = ( $path => $TOKEN );
    is( resolve( $dist, 'given-token' ), 'given-token', 'caller token used' );
    is( scalar @cmds, 0, 'remote not consulted at all' );
  };
}

subtest 'server config carries the token' => sub {
  for my $dist (qw( rke2 k3s )) {
    my $c = Rex::Rancher::Server::_build_server_config( $dist, $TOKEN, undef, undef, undef, 1 );
    is( $c->{token}, $TOKEN, "$dist config.yaml has token" );
  }
};

subtest 'k3s server install command has no token' => sub {
  my $paths = Rex::Rancher::Server::_paths('k3s');
  my $cmd = Rex::Rancher::Server::_k3s_server_install_cmd( $paths, undef );
  unlike( $cmd, qr/K3S_TOKEN/, 'no K3S_TOKEN (first server)' );
  like( $cmd, qr/sh -s - server/, 'explicit server command' );
  unlike( $cmd, qr/K3S_URL/, 'no K3S_URL without server' );

  $cmd = Rex::Rancher::Server::_k3s_server_install_cmd( $paths, 'https://cp1:6443' );
  unlike( $cmd, qr/K3S_TOKEN/, 'no K3S_TOKEN (HA join)' );
  like( $cmd, qr/K3S_URL=https:\/\/cp1:6443 INSTALL_K3S_SKIP_START=true sh -s - server/, 'K3S_URL kept for HA join' );
};

subtest 'agent install commands have no token' => sub {
  my $k3s = Rex::Rancher::Agent::_installer_cmd( 'k3s', 'v1.30.0+k3s1', 'https://cp1:6443' );
  unlike( $k3s, qr/K3S_TOKEN/, 'k3s agent: no K3S_TOKEN' );
  like( $k3s, qr/K3S_URL=https:\/\/cp1:6443/, 'k3s agent: K3S_URL set' );
  like( $k3s, qr/INSTALL_K3S_VERSION=v1\.30\.0\+k3s1/, 'k3s agent: version pin' );
  like( $k3s, qr/sh -s - agent$/, 'k3s agent: explicit agent command' );

  my $rke2 = Rex::Rancher::Agent::_installer_cmd( 'rke2', undef, 'https://cp1:9345' );
  unlike( $rke2, qr/token/i, 'rke2 agent: no token' );
  like( $rke2, qr/INSTALL_RKE2_TYPE=agent/, 'rke2 agent: agent type' );
};

done_testing;
