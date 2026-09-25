use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# gateway_api vs RKE2 v1.37+'s own rke2-gateway-api-crd chart, offline.
#
# - rancher_deploy_server's install_server options: with gateway_api on rke2
#   the default disable list gains rke2-gateway-api-crd; a caller's own list
#   is passed as given (warning when it lacks the chart); nothing changes
#   without gateway_api or on k3s.
# - _ensure_gateway_api_crds dies before fetching or applying anything while
#   RKE2's Helm release exists, and ignores other releases' secrets.
#
# This proves the option plumbing and the guard, not what RKE2 does with
# the chart on a live cluster.
# -----------------------------------------------------------------------------

use Rex::Rancher;
use Rex::Rancher::Cilium;

my @warnings;
{
  no warnings 'redefine';
  *Rex::Logger::info = sub { push @warnings, $_[0] if ( $_[1] // '' ) eq 'warn' };
}

my $CHART   = 'rke2-gateway-api-crd';
my @DEFAULT = @{ Rex::Rancher::Server::_paths('rke2')->{disable} };
my %gw      = ( gateway_api => 1, gateway_api_version => 'v1.2.0' );

sub disable_for { my %o = Rex::Rancher::_gateway_api_disable(@_); $o{disable} }

subtest 'install_server disable list' => sub {
  @warnings = ();
  is_deeply( disable_for(%gw), [ @DEFAULT, $CHART ], 'gateway_api: default plus the chart' );
  is_deeply( disable_for( %gw, distribution => 'rke2' ), [ @DEFAULT, $CHART ], 'explicit rke2 too' );
  is( disable_for(), undef, 'no gateway_api: install_server keeps its default' );
  is( disable_for( gateway_api => 0 ), undef, 'gateway_api => 0: untouched' );
  is( disable_for( %gw, distribution => 'k3s' ), undef, 'k3s: untouched' );
  is_deeply( \@warnings, [], 'no warnings so far' );

  is( disable_for( %gw, disable => [ 'x', $CHART ] ), undef, 'own list with the chart: as given' );
  is( disable_for( %gw, disable => "x,$CHART" ), undef, 'own string with the chart: as given' );
  is_deeply( \@warnings, [], 'own list with the chart: no warning' );

  is( disable_for( %gw, disable => ['x'] ), undef, 'own list without the chart: as given' );
  is( scalar @warnings, 1, '... with a warning' );
  like( $warnings[0], qr/\Q$CHART\E/, '... naming the chart' );

  @warnings = ();
  is( disable_for( %gw, disable => [] ), undef, 'empty list: as given' );
  is( scalar @warnings, 1, '... with a warning' );

  is_deeply( [ @{ Rex::Rancher::Server::_paths('rke2')->{disable} } ], \@DEFAULT,
    'the Server default list is not mutated' );
};

subtest 'rancher_deploy_server hands it to install_server' => sub {
  my %got;
  no warnings 'redefine';
  local *Rex::Rancher::_check_connection        = sub {};
  local *Rex::Rancher::prepare_node             = sub {};
  local *Rex::Rancher::install_server           = sub { %got = @_ };
  local *Rex::Rancher::_save_kubeconfig_locally = sub { $_[1] };
  local *Rex::Rancher::wait_for_api             = sub { 1 };
  local *Rex::Rancher::install_cilium           = sub {};
  Rex::Rancher::rancher_deploy_server( %gw, kubeconfig_file => '/nonexistent/kc.yaml' );
  is_deeply( $got{disable}, [ @DEFAULT, $CHART ], 'gateway_api: chart in the disable list' );
  Rex::Rancher::rancher_deploy_server( kubeconfig_file => '/nonexistent/kc.yaml' );
  ok( !exists $got{disable}, 'no gateway_api: no disable passed' );
};

{
  package FakeAPI;
  sub new { my ( $class, %a ) = @_; bless { %a, selectors => [], gets => 0 }, $class }
  sub list {
    my ( $self, $kind, %a ) = @_;
    push @{ $self->{selectors} }, $a{labelSelector};
    my ($name) = $a{labelSelector} =~ /name=([^,]+)/;
    my @items = map {
      my $s = $_;
      bless { name => $s->{name}, labels => $s->{labels} }, 'FakeSecret'
    } grep { $_->{labels}{name} eq $name } @{ $self->{secrets} };
    return bless { items => \@items }, 'FakeList';
  }
  sub get { $_[0]{gets}++; die "404 not found\n" }
  package FakeList;
  sub items { $_[0]{items} }
  package FakeSecret;
  sub metadata { $_[0] }
  sub name     { $_[0]{name} }
  sub labels   { $_[0]{labels} }
  sub data     { {} }
}

sub secret {
  my ( $name, $status ) = @_;
  return { name => "sh.helm.release.v1.$name.v1",
    labels => { owner => 'helm', name => $name, status => $status, version => 1 } };
}

my %o = ( gateway_api_version => 'v1.2.0', gateway_api_channel => 'experimental' );
my $ensure = Rex::Rancher::Cilium->can('_ensure_gateway_api_crds');

subtest 'RKE2 release owns the CRDs: die before anything' => sub {
  my $api = FakeAPI->new( secrets => [ secret( $CHART, 'deployed' ) ] );
  ok( !eval { $ensure->( $api, \%o ); 1 }, 'dies' );
  like( $@, qr/\Q$CHART\E \(deployed/, 'names the release and its state' );
  like( $@, qr/disable and restart rke2-server/, 'names the way out' );
  is( $api->{gets}, 0, 'before probing or applying any CRD' );
  is( $api->{selectors}[0], "owner=helm,name=$CHART", 'looked in the RKE2 release' );
};

subtest 'no RKE2 release: the apply path runs' => sub {
  my $api = FakeAPI->new( secrets => [ secret( 'cilium', 'deployed' ) ] );
  my @fetched;
  no warnings 'redefine';
  local *HTTP::Tiny::get = sub { push @fetched, $_[1]; die "stop before the network\n" };
  eval { $ensure->( $api, \%o ) };
  is( $@, "stop before the network\n", 'past the guard' );
  is( $api->{gets}, 1, 'CRD probe ran' );
  like( $fetched[0], qr{/v1\.2\.0/experimental-install\.yaml$}, 'bundle fetch reached' );
};

done_testing;
