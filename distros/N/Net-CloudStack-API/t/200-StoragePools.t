##############################################################################
# This test file tests the functions found in the StoragePools section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  cancelStorageMaintenance => {
    description => "Cancels maintenance for primary storage",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "the primary storage ID" } },
    response    => {
      clusterid         => "the ID of the cluster for the storage pool",
      clustername       => "the name of the cluster for the storage pool",
      created           => "the date and time the storage pool was created",
      disksizeallocated => "the host's currently allocated disk size",
      disksizetotal     => "the total disk size of the storage pool",
      id                => "the ID of the storage pool",
      ipaddress         => "the IP address of the storage pool",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool",
      jobstatus => "shows the current pending asynchronous job status",
      name      => "the name of the storage pool",
      path      => "the storage pool path",
      podid     => "the Pod ID of the storage pool",
      podname   => "the Pod name of the storage pool",
      state     => "the state of the storage pool",
      tags      => "the tags for the storage pool",
      type      => "the storage pool type",
      zoneid    => "the Zone ID of the storage pool",
      zonename  => "the Zone name of the storage pool",
    },
    section => "StoragePools",
  },
  createStoragePool => {
    description => "Creates a storage pool.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        clusterid => "the cluster ID for the storage pool",
        details   => "the details for the storage pool",
        podid     => "the Pod ID for the storage pool",
        tags      => "the tags for the storage pool",
      },
      required => {
        name   => "the name for the storage pool",
        url    => "the URL of the storage pool",
        zoneid => "the Zone ID for the storage pool",
      },
    },
    response => {
      clusterid         => "the ID of the cluster for the storage pool",
      clustername       => "the name of the cluster for the storage pool",
      created           => "the date and time the storage pool was created",
      disksizeallocated => "the host's currently allocated disk size",
      disksizetotal     => "the total disk size of the storage pool",
      id                => "the ID of the storage pool",
      ipaddress         => "the IP address of the storage pool",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool",
      jobstatus => "shows the current pending asynchronous job status",
      name      => "the name of the storage pool",
      path      => "the storage pool path",
      podid     => "the Pod ID of the storage pool",
      podname   => "the Pod name of the storage pool",
      state     => "the state of the storage pool",
      tags      => "the tags for the storage pool",
      type      => "the storage pool type",
      zoneid    => "the Zone ID of the storage pool",
      zonename  => "the Zone name of the storage pool",
    },
    section => "StoragePools",
  },
  deleteStoragePool => {
    description => "Deletes a storage pool.",
    isAsync     => "false",
    level       => 1,
    request     => { required => { id => "Storage pool id" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "StoragePools",
  },
  enableStorageMaintenance => {
    description => "Puts storage pool into maintenance state",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "Primary storage ID" } },
    response    => {
      clusterid         => "the ID of the cluster for the storage pool",
      clustername       => "the name of the cluster for the storage pool",
      created           => "the date and time the storage pool was created",
      disksizeallocated => "the host's currently allocated disk size",
      disksizetotal     => "the total disk size of the storage pool",
      id                => "the ID of the storage pool",
      ipaddress         => "the IP address of the storage pool",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool",
      jobstatus => "shows the current pending asynchronous job status",
      name      => "the name of the storage pool",
      path      => "the storage pool path",
      podid     => "the Pod ID of the storage pool",
      podname   => "the Pod name of the storage pool",
      state     => "the state of the storage pool",
      tags      => "the tags for the storage pool",
      type      => "the storage pool type",
      zoneid    => "the Zone ID of the storage pool",
      zonename  => "the Zone name of the storage pool",
    },
    section => "StoragePools",
  },
  listClusters => {
    description => "Lists clusters.",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        allocationstate => "lists clusters by allocation state",
        clustertype     => "lists clusters by cluster type",
        hypervisor      => "lists clusters by hypervisor type",
        id              => "lists clusters by the cluster ID",
        keyword         => "List by keyword",
        managedstate    => "whether this cluster is managed by cloudstack",
        name            => "lists clusters by the cluster name",
        page            => "no description",
        pagesize        => "no description",
        podid           => "lists clusters by Pod ID",
        zoneid          => "lists clusters by Zone ID",
      },
    },
    response => {
      allocationstate => "the allocation state of the cluster",
      clustertype     => "the type of the cluster",
      hypervisortype  => "the hypervisor type of the cluster",
      id              => "the cluster ID",
      managedstate    => "whether this cluster is managed by cloudstack",
      name            => "the cluster name",
      podid           => "the Pod ID of the cluster",
      podname         => "the Pod name of the cluster",
      zoneid          => "the Zone ID of the cluster",
      zonename        => "the Zone name of the cluster",
    },
    section => "StoragePools",
  },
  listStoragePools => {
    description => "Lists storage pools.",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        clusterid => "list storage pools belongig to the specific cluster",
        id        => "the ID of the storage pool",
        ipaddress => "the IP address for the storage pool",
        keyword   => "List by keyword",
        name      => "the name of the storage pool",
        page      => "no description",
        pagesize  => "no description",
        path      => "the storage pool path",
        podid     => "the Pod ID for the storage pool",
        zoneid    => "the Zone ID for the storage pool",
      },
    },
    response => {
      clusterid         => "the ID of the cluster for the storage pool",
      clustername       => "the name of the cluster for the storage pool",
      created           => "the date and time the storage pool was created",
      disksizeallocated => "the host's currently allocated disk size",
      disksizetotal     => "the total disk size of the storage pool",
      id                => "the ID of the storage pool",
      ipaddress         => "the IP address of the storage pool",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool",
      jobstatus => "shows the current pending asynchronous job status",
      name      => "the name of the storage pool",
      path      => "the storage pool path",
      podid     => "the Pod ID of the storage pool",
      podname   => "the Pod name of the storage pool",
      state     => "the state of the storage pool",
      tags      => "the tags for the storage pool",
      type      => "the storage pool type",
      zoneid    => "the Zone ID of the storage pool",
      zonename  => "the Zone name of the storage pool",
    },
    section => "StoragePools",
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
$tests++;       # Test loading of StoragePools group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':StoragePools'; 1", 'use statement' ) } 'use took';
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
