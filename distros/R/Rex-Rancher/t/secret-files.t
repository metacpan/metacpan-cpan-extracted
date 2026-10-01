use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests: config.yaml (join token) and registries.yaml (registry
# passwords) are written 0600 root:root, for server and agent, rke2 and k3s.
#
# `run` and `file` are replaced in Rex::Commands::Run / ::File (the shared
# write_secret_file lives in Rex::Rancher::Distribution, which calls them;
# Server and Agent import them) so no remote host is involved. This proves the command sequence -- tmp pre-created 0600 before
# `file`, chown/chmod after it -- not what a real remote filesystem does.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::Distribution;

my @log;
{
  no warnings 'redefine';
  my $run  = sub { push @log, 'run '.$_[0]; $? = 0; return '' };
  my $file = sub { my ( $p, %o ) = @_; push @log, 'file '.$p; return };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  *Rex::Rancher::Agent::run   = $run;
  *Rex::Commands::File::file  = $file;
  *Rex::Rancher::Server::file = $file;
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
    my $d = Rex::Rancher::Distribution->new_for($dist);
    Rex::Rancher::Server::_write_config( $d, 'tok', undef, undef, undef, 1 );
    $d->write_registries($REG);
    secret_ok( "/etc/rancher/$dist/config.yaml",     'config.yaml' );
    secret_ok( "/etc/rancher/$dist/registries.yaml", 'registries.yaml' );
  };

  subtest "$dist agent" => sub {
    @log = ();
    my $d    = Rex::Rancher::Distribution->new_for( $dist, role => 'agent' );
    my %opts = ( server => 'https://cp1:9345', token => 'tok', registries => $REG );
    Rex::Rancher::Agent::_write_config( $d, %opts );
    Rex::Rancher::Agent::_write_registries( $d, %opts );
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
