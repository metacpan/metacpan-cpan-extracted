use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests: config.yaml (join token) and registries.yaml (registry
# passwords) are written 0600 root:root, for server and agent, rke2 and k3s.
#
# `run` and `file` are replaced in Rex::Rancher::Server (the shared
# _write_secret_file lives there; Agent calls it) so no remote host is
# involved. This proves the command sequence -- tmp pre-created 0600 before
# `file`, chown/chmod after it -- not what a real remote filesystem does.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;

my @log;
{
  no warnings 'redefine';
  *Rex::Rancher::Server::run  = sub { push @log, 'run '.$_[0]; $? = 0; return '' };
  *Rex::Rancher::Server::file = sub { my ( $p, %o ) = @_; push @log, 'file '.$p; return };
  *Rex::Rancher::Agent::run   = sub { push @log, 'run '.$_[0]; $? = 0; return '' };
}

sub secret_ok {
  my ( $path, $what ) = @_;
  ( my $tmp = $path ) =~ s{([^/]+)$}{.rex.tmp.$1};
  my @for = grep { index( $_, $path ) >= 0 || index( $_, $tmp ) >= 0 } @log;
  is_deeply(
    \@for,
    [
      "run install -m 600 -o root -g root /dev/null $tmp",
      "file $path",
      "run chown root:root $path && chmod 600 $path",
    ],
    "$what: tmp pre-created 0600, file written, then chown+chmod 600"
  );
}

my $REG = { configs => { 'r:5000' => { auth => { username => 'u', password => 'p' } } } };

for my $dist (qw( rke2 k3s )) {
  subtest "$dist server" => sub {
    @log = ();
    my $paths = Rex::Rancher::Server::_paths($dist);
    Rex::Rancher::Server::_write_config( $paths, $dist, 'tok', undef, undef, undef, 1 );
    Rex::Rancher::Server::_generate_registries_yaml( $paths->{config_dir}, $REG );
    secret_ok( "/etc/rancher/$dist/config.yaml",     'config.yaml' );
    secret_ok( "/etc/rancher/$dist/registries.yaml", 'registries.yaml' );
  };

  subtest "$dist agent" => sub {
    @log = ();
    my $paths = Rex::Rancher::Agent::_paths($dist);
    my %opts  = ( server => 'https://cp1:9345', token => 'tok', registries => $REG );
    Rex::Rancher::Agent::_write_config( $paths, $dist, %opts );
    Rex::Rancher::Agent::_write_registries( $paths, %opts );
    secret_ok( "/etc/rancher/$dist/config.yaml",     'config.yaml' );
    secret_ok( "/etc/rancher/$dist/registries.yaml", 'registries.yaml' );
  };
}

subtest 'tmp name follows Rex' => sub {
  is( Rex::Commands::File::get_tmp_file_name('/etc/rancher/rke2/config.yaml'),
    '/etc/rancher/rke2/.rex.tmp.config.yaml',
    'pre-created path is the one Rex file() writes to' );
};

done_testing;
