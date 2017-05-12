##############################################################################
# This test file tests the functions found in the NetAppIntegration section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  associateLun => {
    description => "Associate a LUN with a guest IQN",
    isAsync     => "false",
    level       => 15,
    request     => { required => { iqn => "Guest IQN to which the LUN associate.", name => "LUN name." }, },
    response    => { id => "the LUN id", ipaddress => "the IP address of", targetiqn => "the target IQN", },
    section     => "NetAppIntegration",
  },
  createLunOnFiler => {
    description => "Create a LUN from a pool",
    isAsync     => "false",
    level       => 15,
    request     => { required => { name => "pool name.", size => "LUN size." } },
    response    => { ipaddress => "ip address", iqn => "iqn", path => "pool path" },
    section     => "NetAppIntegration",
  },
  createPool => {
    description => "Create a pool",
    isAsync     => "false",
    level       => 15,
    request     => { required => { algorithm => "algorithm.", name => "pool name." } },
    response    => undef,
    section     => "NetAppIntegration",
  },
  createVolumeOnFiler => {
    description => "Create a volume",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => { snapshotpolicy => "snapshot policy.", snapshotreservation => "snapshot reservation.", },
      required => {
        aggregatename => "aggregate name.",
        ipaddress     => "ip address.",
        password      => "password.",
        poolname      => "pool name.",
        size          => "volume size.",
        username      => "user name.",
        volumename    => "volume name.",
      },
    },
    response => undef,
    section  => "NetAppIntegration",
  },
  deletePool => {
    description => "Delete a pool",
    isAsync     => "false",
    level       => 15,
    request     => { required => { poolname => "pool name." } },
    response    => undef,
    section     => "NetAppIntegration",
  },
  destroyLunOnFiler => {
    description => "Destroy a LUN",
    isAsync     => "false",
    level       => 15,
    request     => { required => { path => "LUN path." } },
    response    => undef,
    section     => "NetAppIntegration",
  },
  destroyVolumeOnFiler => {
    description => "Destroy a Volume",
    isAsync     => "false",
    level       => 15,
    request     => {
      required => { aggregatename => "aggregate name.", ipaddress => "ip address.", volumename => "volume name.", },
    },
    response => undef,
    section  => "NetAppIntegration",
  },
  dissociateLun => {
    description => "Dissociate a LUN",
    isAsync     => "false",
    level       => 15,
    request     => { required => { iqn => "Guest IQN.", path => "LUN path." } },
    response    => undef,
    section     => "NetAppIntegration",
  },
  listLunsOnFiler => {
    description => "List LUN",
    isAsync     => "false",
    level       => 15,
    request     => { required => { poolname => "pool name." } },
    response    => { id => "lun id", iqn => "lun iqn", name => "lun name", volumeid => "volume id", },
    section     => "NetAppIntegration",
  },
  listPools => {
    description => "List Pool",
    isAsync     => "false",
    level       => 15,
    request     => undef,
    response    => { algorithm => "pool algorithm", id => "pool id", name => "pool name" },
    section     => "NetAppIntegration",
  },
  listVolumesOnFiler => {
    description => "List Volumes",
    isAsync     => "false",
    level       => 15,
    request     => { required => { poolname => "pool name." } },
    response    => {
      aggregatename       => "Aggregate name",
      id                  => "volume id",
      ipaddress           => "ip address",
      poolname            => "pool name",
      size                => "volume size",
      snapshotpolicy      => "snapshot policy",
      snapshotreservation => "snapshot reservation",
      volumename          => "Volume name",
    },
    section => "NetAppIntegration",
  },
  modifyPool => {
    description => "Modify pool",
    isAsync     => "false",
    level       => 15,
    request     => { required => { algorithm => "algorithm.", poolname => "pool name." }, },
    response    => undef,
    section     => "NetAppIntegration",
  },
};

sub random_text {

  my @c = ( 'a' .. 'z', 'A' .. 'Z' );
  return join '', map { $c[ rand @c ] } 0 .. int( rand 16 ) + 8;

}

my $base_url   = 'http://somecloud.com';
my $api_path   = 'client/api?';
my $api_key    = random_text();
my $secret_key = random_text();

my $tests = 1;  # Start at 1 for Test::NoWarnings
$tests++;       # Test loading of NetAppIntegration group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':NetAppIntegration'; 1", 'use statement' ) } 'use took';
explain $@ if $@;

my $obj = Net::CloudStack::API->new;
isa_ok( $obj, 'Net::CloudStack::API' );

my $oo_api = $obj->api( {

    base_url   => $base_url,
    api_path   => $api_path,
    api_key    => $api_key,
    secret_key => $secret_key,

} );

isa_ok( $oo_api, 'Net::CloudStack' );

# MatchURL::match expects
# $check_url, $base_url, $api_path, $api_key, $secret_key, $cmd, $pairs (optional)
my @data = ( $base_url, $api_path, $api_key, $secret_key );

for my $m ( keys %$method ) {

  explain( "Working on $m method" );

  my $work = $method->{ $m };

  SKIP: {

    skip 'no required parameters', 2
        if ! exists $work->{ request }{ required };

    # Test call with no arguments
    my $check_regex = qr/Mandatory parameters? .*? missing in call/i;
    throws_ok { $obj->$m } $check_regex, 'caught missing required params (oo)';

    no strict 'refs';
    throws_ok { $m->() } $check_regex, 'caught missing required params (functional)';

  }

  my ( %args, @args );

  if ( exists $work->{ request }{ required } ) {
    for my $parm ( keys %{ $work->{ request }{ required } } ) {

      $args{ $parm } = random_text();
      push @args, [ $parm, $args{ $parm } ];

    }
  }

  my $check_url;
  ok( $check_url = $obj->$m( \%args ), 'check_url created (oo)' );
  ok( MatchURL::match( $check_url, @data, $m, \@args ), 'urls matched (oo)' );

  { no strict 'refs'; ok( $check_url = $m->( \%args ), 'check_url created (functional)' ) }
  ok( MatchURL::match( $check_url, @data, $m, \@args ), 'urls matched (functional)' );

} ## end for my $m ( keys %$method)
