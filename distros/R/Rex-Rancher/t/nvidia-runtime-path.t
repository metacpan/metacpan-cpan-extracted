use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests for nvidia_runtime_path: the PATH line rke2 needs in
# /etc/default/rke2-{server,agent} to find a host-installed
# nvidia-container-runtime at service start (its unit sets no PATH).
#
# - the env file keeps its other lines, carries exactly one PATH line, and a
#   file that already has it is not rewritten;
# - nothing is written without nvidia-container-runtime on the host, on k3s,
#   or without the option;
# - install_agent writes it before the installer and the service start.
#
# run, can_run and file are faked; this proves the decision and the content,
# not that rke2 wires the runtime -- that needs a live GPU node.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;

my $LINE = 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

# Fake remote: %files maps path => content, @log records commands and writes in
# order, $runtime says whether nvidia-container-runtime is on the host.
my ( %files, @log, $runtime, $service_running );
my $run = sub {
  my ( $cmd ) = @_;
  push @log, $cmd;
  if ( $cmd =~ m{^cat (\S+)} ) {
    if ( exists $files{$1} ) { $? = 0; return $files{$1} }
    $? = 1 << 8;
    return '';
  }
  if ( $cmd =~ m{^systemctl is-active --quiet} ) { $? = ( $service_running ? 0 : 3 ) << 8; return '' }
  if ( $cmd =~ m{^systemctl is-active} ) { $? = 0; return "active\n" }
  if ( $cmd =~ m{^command -v rke2} ) { $? = 0; return "/usr/local/bin/rke2\n" }
  if ( $cmd =~ m{/dev/urandom} ) { $? = 0; return 'G' x 48 }
  if ( $cmd =~ m{^test -f .* && echo yes} ) { $? = 0; return "yes\n" }
  $? = 0;
  return '';
};
my $file = sub {
  my ( $path, %args ) = @_;
  push @log, "file $path";
  $files{$path} = $args{content} if exists $args{content};
};
{
  no warnings 'redefine';
  *Rex::Rancher::Server::run     = $run;
  *Rex::Rancher::Agent::run      = $run;
  *Rex::Rancher::Server::file    = $file;
  *Rex::Rancher::Server::can_run = sub { $runtime ? '/usr/bin/nvidia-container-runtime' : undef };
}

sub reset_remote { %files = @_; @log = (); $runtime = 1; $service_running = 0 }

my $env = \&Rex::Rancher::Server::_env_with_runtime_path;

subtest '_env_with_runtime_path' => sub {
  is( $env->(undef), "$LINE\n", 'no file: only the PATH line' );
  is( $env->(''),    "$LINE\n", 'empty file: only the PATH line' );
  is( $env->("RKE2_FOO=1\n# comment\n"), "RKE2_FOO=1\n# comment\n$LINE\n",
    'other lines kept in order, PATH appended' );
  is( $env->("PATH=/opt/bin\nHTTP_PROXY=http://p:3128\n"), "HTTP_PROXY=http://p:3128\n$LINE\n",
    'existing PATH replaced, other lines kept' );
  is( $env->("PATH=/a\nX=1\nPATH=/b"), "X=1\n$LINE\n", 'several PATH lines collapse to one' );
  is( $env->("X=1\n$LINE\n"), undef, 'already right: unchanged' );
  is( $env->("$LINE\nX=1\n"), "X=1\n$LINE\n", 'ours not last: rewritten once ...' );
  is( $env->( $env->("$LINE\nX=1\n") ), undef, '... then stable' );
};

my %paths = map { $_ => Rex::Rancher::Server::_paths($_) } qw( rke2 k3s );
my $writes = sub { grep { /^file / } @log };

subtest 'rke2 server: written, other lines kept' => sub {
  reset_remote( '/etc/default/rke2-server' => "HTTP_PROXY=http://p:3128\n" );
  Rex::Rancher::Server::_nvidia_runtime_path( $paths{rke2} );
  is( $files{'/etc/default/rke2-server'}, "HTTP_PROXY=http://p:3128\n$LINE\n", 'content' );
  ok( !grep( { /restart/ } @log ), 'nothing restarted' );
};

subtest 'rke2 server: already right, not rewritten' => sub {
  reset_remote( '/etc/default/rke2-server' => "$LINE\n" );
  Rex::Rancher::Server::_nvidia_runtime_path( $paths{rke2} );
  is( scalar $writes->(), 0, 'no write' );
};

subtest 'no nvidia-container-runtime on the host: nothing written' => sub {
  reset_remote();
  $runtime = 0;
  Rex::Rancher::Server::_nvidia_runtime_path( $paths{rke2} );
  is( scalar @log, 0, 'no command, no write' );
};

subtest 'k3s: nothing written' => sub {
  reset_remote();
  Rex::Rancher::Server::_nvidia_runtime_path( $paths{k3s} );
  is( scalar @log, 0, 'no command, no write' );
};

subtest 'running service: file written, no restart' => sub {
  reset_remote();
  $service_running = 1;
  Rex::Rancher::Server::_nvidia_runtime_path( $paths{rke2} );
  is( $files{'/etc/default/rke2-server'}, "$LINE\n", 'written' );
  ok( !grep( { /systemctl (re)?start|restart/ } @log ), 'no (re)start' );
};

subtest 'rke2 server: written before the installer and the service start' => sub {
  reset_remote();
  install_server( nvidia_runtime_path => 1 );
  my @order = grep { m{^file /etc/default/|get\.rke2\.io|systemctl start} } @log;
  is_deeply( \@order,
    [ 'file /etc/default/rke2-server',
      'curl -sfL https://get.rke2.io | sh -',
      'systemctl start --no-block rke2-server' ],
    'env file, installer, start' );
};

subtest 'server without the option: no env file' => sub {
  reset_remote();
  install_server();
  ok( !grep( { m{/etc/default/} } @log ), 'untouched' );
};

subtest 'rke2 agent: written before the installer and the service start' => sub {
  reset_remote();
  install_agent( server => 'https://cp1:9345', token => 't', nvidia_runtime_path => 1 );
  my @order = grep { m{^file /etc/default/|get\.rke2\.io|systemctl start} } @log;
  is_deeply( \@order,
    [ 'file /etc/default/rke2-agent',
      'curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -',
      'systemctl start --no-block rke2-agent.service' ],
    'env file, installer, start' );
  is( $files{'/etc/default/rke2-agent'}, "$LINE\n", 'rke2-agent content' );
};

subtest 'agent without the option: no env file' => sub {
  reset_remote();
  install_agent( server => 'https://cp1:9345', token => 't' );
  ok( !grep( { m{/etc/default/} } @log ), 'untouched' );
};

subtest 'k3s agent with the option: no env file' => sub {
  reset_remote();
  install_agent( distribution => 'k3s', server => 'https://cp1:6443', token => 't',
    nvidia_runtime_path => 1 );
  ok( !grep( { m{/etc/default/} } @log ), 'untouched' );
};

done_testing;
