use strict;
use warnings;
use Test::More;

use Rex::Rancher;

# -----------------------------------------------------------------------------
# k75: with gpu_setup running (gpu => 1, gpu_setup not 0) rancher_deploy_server
# and rancher_deploy_agent need Rex::GPU 0.002 or later: 0.001 writes a bare
# containerd config.toml.tmpl on every run. An older, missing or unloadable
# Rex::GPU dies before the connection check and any host step, naming the
# installed version. Without gpu_setup Rex::GPU is not loaded at all.
#
# Offline: Rex::GPU comes only from the @INC hook below, every host step is a
# fake that records what ran. This proves the check and its place in the
# pipeline, not a GPU deploy.
# -----------------------------------------------------------------------------

my @perl_warnings;
$SIG{__WARN__} = sub { push @perl_warnings, @_ };

# What "is installed": undef = nothing, 'broken' = a Rex::GPU whose own
# dependency is missing, '' = one without a $VERSION, else that version.
our ( $gpu, @gpu_loads, @gpu_setup_calls );
{
  package Rex::GPU;
  sub import {}
  sub gpu_setup { push @main::gpu_setup_calls, {@_} }
}
unshift @INC, sub {
  my ( undef, $file ) = @_;
  return unless $file eq 'Rex/GPU.pm';
  push @gpu_loads, $file;
  die "Can't locate Rex/GPU.pm in \@INC (you may need to install the Rex::GPU module) "
    ."(\@INC entries checked: /fake)\n" unless defined $gpu;
  my $src =
      $gpu eq 'broken' ? 'package Rex::GPU; use Rex::GPU::Missing::Dependency; 1;'
    : length $gpu      ? "package Rex::GPU; \$Rex::GPU::VERSION = '$gpu'; 1;"
    :                    'package Rex::GPU; undef $Rex::GPU::VERSION; 1;';
  open my $fh, '<', \$src or die;
  return $fh;
};

my @ran;
no warnings 'redefine';
local *Rex::Rancher::_check_connection           = sub { push @ran, 'check_connection' };
local *Rex::Rancher::prepare_node                = sub { push @ran, 'prepare_node' };
local *Rex::Rancher::install_server              = sub { push @ran, 'install_server' };
local *Rex::Rancher::install_agent               = sub { push @ran, 'install_agent' };
# k78's preflight, not this test's concern (covered by t/deploy-preflight.t).
local *Rex::Rancher::Server::preflight_server    = sub { {} };
local *Rex::Rancher::Agent::preflight_agent      = sub { {} };
local *Rex::Rancher::_save_kubeconfig_locally    = sub { push @ran, 'save_kubeconfig'; $_[1] };
local *Rex::Rancher::wait_for_api                = sub { push @ran, 'wait_for_api'; 1 };
local *Rex::Rancher::install_cilium              = sub { push @ran, 'install_cilium' };
local *Rex::Rancher::deploy_nvidia_device_plugin = sub { push @ran, 'device_plugin' };
local *Rex::Commands::Run::run                   = sub { push @ran, 'run '.$_[0]; '' };
local *Rex::Commands::File::file                 = sub { push @ran, 'file '.$_[0] };
use warnings 'redefine';

sub reset_host {
  ( $gpu ) = @_;
  ( @ran, @gpu_loads, @gpu_setup_calls ) = ();
  delete $INC{'Rex/GPU.pm'};
  undef $Rex::GPU::VERSION;
}

my %deploy = (
  server => sub {
    my ( $dist, %o ) = @_;
    Rex::Rancher::rancher_deploy_server( distribution => $dist,
      kubeconfig_file => '/nonexistent/kc.yaml', tls_san => '10.0.0.1', %o );
  },
  agent  => sub {
    my ( $dist, %o ) = @_;
    Rex::Rancher::rancher_deploy_agent( distribution => $dist, token => 't',
      server => ( $dist eq 'k3s' ? 'https://cp:6443' : 'https://cp:9345' ), %o );
  },
);

my %refused = (
  'not installed'  => [ undef,    qr/^gpu => 1 requested but Rex::GPU is not installed\. / ],
  '0.001'          => [ '0.001',  qr/^gpu => 1 requested but Rex::GPU 0\.001 is installed, and gpu_setup needs 0\.002 or later: / ],
  'no $VERSION'    => [ '',       qr/^gpu => 1 requested but Rex::GPU without a version is installed, and gpu_setup needs 0\.002 or later/ ],
  'does not load'  => [ 'broken', qr/^gpu => 1 requested but Rex::GPU could not be loaded: Can't locate Rex\/GPU\/Missing\/Dependency\.pm/ ],
);

for my $role (qw( server agent )) {
  for my $dist (qw( rke2 k3s )) {
    my $label = $role.', '.$dist;

    for my $case (sort keys %refused) {
      my ( $have, $msg ) = @{ $refused{$case} };
      reset_host($have);
      ok( !eval { $deploy{$role}->( $dist, gpu => 1 ); 1 }, $label.', Rex::GPU '.$case.': dies' );
      like( $@, $msg, $label.', Rex::GPU '.$case.': says what is installed' );
      like( $@, qr/Install Rex-GPU 0\.002 or later, or pass gpu_setup => 0 /, '... how to get past it' );
      like( $@, qr/; nothing was done on the host\n\z/, '... that the host is untouched, no line number' );
      is_deeply( \@ran, [], '... before the connection check and any host step' );
      is_deeply( \@gpu_setup_calls, [], '... gpu_setup not called' );
    }

    for my $have (qw( 0.002 0.003 )) {
      reset_host($have);
      ok( eval { $deploy{$role}->( $dist, gpu => 1, gpu_device_plugin => 0 ); 1 },
        $label.', Rex::GPU '.$have.': accepted' ) or diag $@;
      is( scalar @gpu_loads, 1, '... loaded once' );
      is( scalar @gpu_setup_calls, 1, '... gpu_setup runs' );
      is_deeply( [ @ran[0, 1] ], [qw( check_connection prepare_node )], '... the pipeline goes on' );
    }

    for my $off ( [ 'gpu_setup => 0', gpu => 1, gpu_setup => 0, gpu_device_plugin => 0 ],
                  [ 'no gpu' ] ) {
      my ( $what, %o ) = @$off;
      reset_host('0.001');
      ok( eval { $deploy{$role}->( $dist, %o ); 1 }, $label.', '.$what.' with Rex::GPU 0.001: fine' )
        or diag $@;
      is_deeply( \@gpu_loads, [], '... Rex::GPU not loaded' );
      is_deeply( \@gpu_setup_calls, [], '... gpu_setup not called' );
    }
  }
}

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
