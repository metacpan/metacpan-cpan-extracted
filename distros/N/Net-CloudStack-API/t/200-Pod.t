##############################################################################
# This test file tests the functions found in the Pod section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createPod => {
    description => "Creates a new Pod.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        allocationstate => "Allocation state of this Pod for allocation of new resources",
        endip           => "the ending IP address for the Pod",
      },
      required => {
        gateway => "the gateway for the Pod",
        name    => "the name of the Pod",
        netmask => "the netmask for the Pod",
        startip => "the starting IP address for the Pod",
        zoneid  => "the Zone ID in which the Pod will be created",
      },
    },
    response => {
      allocationstate => "the allocation state of the cluster",
      endip           => "the ending IP for the Pod",
      gateway         => "the gateway of the Pod",
      id              => "the ID of the Pod",
      name            => "the name of the Pod",
      netmask         => "the netmask of the Pod",
      startip         => "the starting IP for the Pod",
      zoneid          => "the Zone ID of the Pod",
      zonename        => "the Zone name of the Pod",
    },
    section => "Pod",
  },
  deletePod => {
    description => "Deletes a Pod.",
    isAsync     => "false",
    level       => 1,
    request     => { required => { id => "the ID of the Pod" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Pod",
  },
  listPods => {
    description => "Lists all Pods.",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        allocationstate => "list pods by allocation state",
        id              => "list Pods by ID",
        keyword         => "List by keyword",
        name            => "list Pods by name",
        page            => "no description",
        pagesize        => "no description",
        zoneid          => "list Pods by Zone ID",
      },
    },
    response => {
      allocationstate => "the allocation state of the cluster",
      endip           => "the ending IP for the Pod",
      gateway         => "the gateway of the Pod",
      id              => "the ID of the Pod",
      name            => "the name of the Pod",
      netmask         => "the netmask of the Pod",
      startip         => "the starting IP for the Pod",
      zoneid          => "the Zone ID of the Pod",
      zonename        => "the Zone name of the Pod",
    },
    section => "Pod",
  },
  updatePod => {
    description => "Updates a Pod.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        allocationstate => "Allocation state of this cluster for allocation of new resources",
        endip           => "the ending IP address for the Pod",
        gateway         => "the gateway for the Pod",
        name            => "the name of the Pod",
        netmask         => "the netmask of the Pod",
        startip         => "the starting IP address for the Pod",
      },
      required => { id => "the ID of the Pod" },
    },
    response => {
      allocationstate => "the allocation state of the cluster",
      endip           => "the ending IP for the Pod",
      gateway         => "the gateway of the Pod",
      id              => "the ID of the Pod",
      name            => "the name of the Pod",
      netmask         => "the netmask of the Pod",
      startip         => "the starting IP for the Pod",
      zoneid          => "the Zone ID of the Pod",
      zonename        => "the Zone name of the Pod",
    },
    section => "Pod",
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
$tests++;       # Test loading of Pod group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Pod'; 1", 'use statement' ) } 'use took';
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
