##############################################################################
# This test file tests the functions found in the ExternalLoadBalancer section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  addExternalLoadBalancer => {
    description => "Adds an external load balancer appliance.",
    isAsync     => "false",
    level       => 1,
    request     => {
      required => {
        password => "Password of the external load balancer appliance.",
        url      => "URL of the external load balancer appliance.",
        username => "Username of the external load balancer appliance.",
        zoneid   => "Zone in which to add the external load balancer appliance.",
      },
    },
    response => {
      id               => "the ID of the external load balancer",
      inline           => "configures the external load balancer to be inline with an external firewall",
      ipaddress        => "the management IP address of the external load balancer",
      numretries       => "the number of times to retry requests to the external load balancer",
      privateinterface => "the private interface of the external load balancer",
      publicinterface  => "the public interface of the external load balancer",
      username         => "the username that's used to log in to the external load balancer",
      zoneid           => "the zone ID of the external load balancer",
    },
    section => "ExternalLoadBalancer",
  },
  deleteExternalLoadBalancer => {
    description => "Deletes an external load balancer appliance.",
    isAsync     => "false",
    level       => 1,
    request     => { required => { id => "Id of the external loadbalancer appliance." }, },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "ExternalLoadBalancer",
  },
  listExternalLoadBalancers => {
    description => "List external load balancer appliances.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
        zoneid   => "zone Id",
      },
    },
    response => {
      allocationstate         => "the allocation state of the host",
      averageload             => "the cpu average load on the host",
      capabilities            => "capabilities of the host",
      clusterid               => "the cluster ID of the host",
      clustername             => "the cluster name of the host",
      clustertype             => "the cluster type of the cluster that host belongs to",
      cpuallocated            => "the amount of the host's CPU currently allocated",
      cpunumber               => "the CPU number of the host",
      cpuspeed                => "the CPU speed of the host",
      cpuused                 => "the amount of the host's CPU currently used",
      cpuwithoverprovisioning => "the amount of the host's CPU after applying the cpu.overprovisioning.factor",
      created                 => "the date and time the host was created",
      disconnected            => "true if the host is disconnected. False otherwise.",
      disksizeallocated       => "the host's currently allocated disk size",
      disksizetotal           => "the total disk size of the host",
      events                  => "events available for the host",
      hasEnoughCapacity => "true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise",
      hosttags          => "comma-separated list of tags for the host",
      hypervisor        => "the host hypervisor",
      id                => "the ID of the host",
      ipaddress         => "the IP address of the host",
      islocalstorageactive => "true if local storage is active, false otherwise",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host",
      jobstatus          => "shows the current pending asynchronous job status",
      lastpinged         => "the date and time the host was last pinged",
      managementserverid => "the management server ID of the host",
      memoryallocated    => "the amount of the host's memory currently allocated",
      memorytotal        => "the memory total of the host",
      memoryused         => "the amount of the host's memory currently used",
      name               => "the name of the host",
      networkkbsread     => "the incoming network traffic on the host",
      networkkbswrite    => "the outgoing network traffic on the host",
      oscategoryid       => "the OS category ID of the host",
      oscategoryname     => "the OS category name of the host",
      podid              => "the Pod ID of the host",
      podname            => "the Pod name of the host",
      removed            => "the date and time the host was removed",
      state              => "the state of the host",
      type               => "the host type",
      version            => "the host version",
      zoneid             => "the Zone ID of the host",
      zonename           => "the Zone name of the host",
    },
    section => "ExternalLoadBalancer",
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
$tests++;       # Test loading of ExternalLoadBalancer group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':ExternalLoadBalancer'; 1", 'use statement' ) } 'use took';
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
