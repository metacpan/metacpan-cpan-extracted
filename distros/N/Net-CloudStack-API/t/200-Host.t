##############################################################################
# This test file tests the functions found in the Host section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  addCluster => {
    description => "Adds a new cluster",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        allocationstate => "Allocation state of this cluster for allocation of new resources",
        password        => "the password for the host",
        podid           => "the Pod ID for the host",
        url             => "the URL",
        username        => "the username for the cluster",
      },
      required => {
        clustername => "the cluster name",
        clustertype => "type of the cluster: CloudManaged, ExternalManaged",
        hypervisor  => "hypervisor type of the cluster: XenServer,KVM,VMware,Hyperv,BareMetal,Simulator",
        zoneid      => "the Zone ID for the cluster",
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
    section => "Host",
  },
  addHost => {
    description => "Adds a new host.",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        allocationstate => "Allocation state of this Host for allocation of new resources",
        clusterid       => "the cluster ID for the host",
        clustername     => "the cluster name for the host",
        hosttags        => "list of tags to be added to the host",
        podid           => "the Pod ID for the host",
      },
      required => {
        hypervisor => "hypervisor type of the host",
        password   => "the password for the host",
        url        => "the host URL",
        username   => "the username for the host",
        zoneid     => "the Zone ID for the host",
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
    section => "Host",
  },
  addSecondaryStorage => {
    description => "Adds secondary storage.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => { zoneid => "the Zone ID for the secondary storage" },
      required => { url    => "the URL for the secondary storage" },
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
    section => "Host",
  },
  cancelHostMaintenance => {
    description => "Cancels host maintenance.",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "the host ID" } },
    response    => {
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
    section => "Host",
  },
  deleteCluster => {
    description => "Deletes a cluster.",
    isAsync     => "false",
    level       => 1,
    request     => { required => { id => "the cluster ID" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Host",
  },
  deleteHost => {
    description => "Deletes a host.",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        forced =>
            "Force delete the host. All HA enabled vms running on the host will be put to HA; HA disabled ones will be stopped",
        forcedestroylocalstorage =>
            "Force destroy local storage on this host. All VMs created on this local storage will be destroyed",
      },
      required => { id => "the host ID" },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Host",
  },
  listHosts => {
    description => "Lists hosts.",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        allocationstate => "list hosts by allocation state",
        clusterid       => "lists hosts existing in particular cluster",
        details =>
            "give details.  1 = minimal; 2 = include static info; 3 = include events; 4 = include allocation and statistics",
        id       => "the id of the host",
        keyword  => "List by keyword",
        name     => "the name of the host",
        page     => "no description",
        pagesize => "no description",
        podid    => "the Pod ID for the host",
        state    => "the state of the host",
        type     => "the host type",
        virtualmachineid =>
            "lists hosts in the same cluster as this VM and flag hosts with enough CPU/RAm to host this VM",
        zoneid => "the Zone ID for the host",
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
    section => "Host",
  },
  prepareHostForMaintenance => {
    description => "Prepares a host for maintenance.",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "the host ID" } },
    response    => {
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
    section => "Host",
  },
  reconnectHost => {
    description => "Reconnects a host.",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "the host ID" } },
    response    => {
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
    section => "Host",
  },
  updateCluster => {
    description => "Updates an existing cluster",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        allocationstate => "Allocation state of this cluster for allocation of new resources",
        clustername     => "the cluster name",
        clustertype     => "hypervisor type of the cluster",
        hypervisor      => "hypervisor type of the cluster",
        managedstate    => "whether this cluster is managed by cloudstack",
      },
      required => { id => "the ID of the Cluster" },
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
    section => "Host",
  },
  updateHost => {
    description => "Updates a host.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        allocationstate => "Allocation state of this Host for allocation of new resources",
        hosttags        => "list of tags to be added to the host",
        oscategoryid    => "the id of Os category to update the host with",
      },
      required => { id => "the ID of the host to update" },
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
    section => "Host",
  },
  updateHostPassword => {
    description => "Update password of a host/pool on management server.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        clusterid => "the cluster ID. Either this parameter, or hostId has to be passed in",
        hostid    => "the host ID. Either this parameter, or clusterId has to be passed in",
      },
      required =>
          { password => "the new password for the host/cluster", username => "the username for the host/cluster", },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Host",
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
$tests++;       # Test loading of Host group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Host'; 1", 'use statement' ) } 'use took';
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
