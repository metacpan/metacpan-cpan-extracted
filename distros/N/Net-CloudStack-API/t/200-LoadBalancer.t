##############################################################################
# This test file tests the functions found in the LoadBalancer section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  assignToLoadBalancerRule => {
    description => "Assigns virtual machine or a list of virtual machines to a load balancer rule.",
    isAsync     => "true",
    level       => 15,
    request     => {
      required => {
        id => "the ID of the load balancer rule",
        virtualmachineids =>
            "the list of IDs of the virtual machine that are being assigned to the load balancer rule(i.e. virtualMachineIds=1,2,3)",
      },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "LoadBalancer",
  },
  createLoadBalancerRule => {
    description => "Creates a load balancer rule",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        account     => "the account associated with the load balancer. Must be used with the domainId parameter.",
        cidrlist    => "the cidr list to forward traffic from",
        description => "the description of the load balancer rule",
        domainid    => "the domain ID associated with the load balancer",
        openfirewall =>
            "if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default",
        publicipid => "public ip address id from where the network traffic will be load balanced from",
        zoneid     => "public ip address id from where the network traffic will be load balanced from",
      },
      required => {
        algorithm => "load balancer algorithm (source, roundrobin, leastconn)",
        name      => "name of the load balancer rule",
        privateport =>
            "the private port of the private ip address/virtual machine where the network traffic will be load balanced to",
        publicport => "the public port from where the network traffic will be load balanced from",
      },
    },
    response => {
      account     => "the account of the load balancer rule",
      algorithm   => "the load balancer algorithm (source, roundrobin, leastconn)",
      cidrlist    => "the cidr list to forward traffic from",
      description => "the description of the load balancer",
      domain      => "the domain of the load balancer rule",
      domainid    => "the domain ID of the load balancer rule",
      id          => "the load balancer rule ID",
      name        => "the name of the load balancer",
      privateport => "the private port",
      publicip    => "the public ip address",
      publicipid  => "the public ip address id",
      publicport  => "the public port",
      state       => "the state of the rule",
      zoneid      => "the id of the zone the rule belongs to",
    },
    section => "LoadBalancer",
  },
  deleteLoadBalancerRule => {
    description => "Deletes a load balancer rule.",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "the ID of the load balancer rule" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "LoadBalancer",
  },
  listLoadBalancerRuleInstances => {
    description => "List all virtual machine instances that are assigned to a load balancer rule.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        applied  => "true if listing all virtual machines currently applied to the load balancer rule; default is true",
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
      },
      required => { id => "the ID of the load balancer rule" },
    },
    response => {
      "account"     => "the account associated with the virtual machine",
      "cpunumber"   => "the number of cpu this virtual machine is running with",
      "cpuspeed"    => "the speed of each cpu",
      "cpuused"     => "the amount of the vm's CPU currently used",
      "created"     => "the date when this virtual machine was created",
      "displayname" => "user generated name. The name of the virtual machine is returned if no displayname exists.",
      "domain"      => "the name of the domain in which the virtual machine exists",
      "domainid"    => "the ID of the domain in which the virtual machine exists",
      "forvirtualnetwork" => "the virtual network for the service offering",
      "group"             => "the group name of the virtual machine",
      "groupid"           => "the group ID of the virtual machine",
      "guestosid"         => "Os type ID of the virtual machine",
      "haenable"          => "true if high-availability is enabled, false otherwise",
      "hostid"            => "the ID of the host for the virtual machine",
      "hostname"          => "the name of the host for the virtual machine",
      "hypervisor"        => "the hypervisor on which the template runs",
      "id"                => "the ID of the virtual machine",
      "ipaddress"         => "the ip address of the virtual machine",
      "isodisplaytext"    => "an alternate display text of the ISO attached to the virtual machine",
      "isoid"             => "the ID of the ISO attached to the virtual machine",
      "isoname"           => "the name of the ISO attached to the virtual machine",
      "jobid" =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine",
      "jobstatus"           => "shows the current pending asynchronous job status",
      "memory"              => "the memory allocated for the virtual machine",
      "name"                => "the name of the virtual machine",
      "networkkbsread"      => "the incoming network traffic on the vm",
      "networkkbswrite"     => "the outgoing network traffic on the host",
      "nic(*)"              => "the list of nics associated with vm",
      "password"            => "the password (if exists) of the virtual machine",
      "passwordenabled"     => "true if the password rest feature is enabled, false otherwise",
      "rootdeviceid"        => "device ID of the root volume",
      "rootdevicetype"      => "device type of the root volume",
      "securitygroup(*)"    => "list of security groups associated with the virtual machine",
      "serviceofferingid"   => "the ID of the service offering of the virtual machine",
      "serviceofferingname" => "the name of the service offering of the virtual machine",
      "state"               => "the state of the virtual machine",
      "templatedisplaytext" => "an alternate display text of the template for the virtual machine",
      "templateid" =>
          "the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.",
      "templatename" => "the name of the template for the virtual machine",
      "zoneid"       => "the ID of the availablility zone for the virtual machine",
      "zonename"     => "the name of the availability zone for the virtual machine",
    },
    section => "LoadBalancer",
  },
  listLoadBalancerRules => {
    description => "Lists load balancer rules.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "the account of the load balancer rule. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID of the load balancer rule. If used with the account parameter, lists load balancer rules for the account in the specified domain.",
        id               => "the ID of the load balancer rule",
        keyword          => "List by keyword",
        name             => "the name of the load balancer rule",
        page             => "no description",
        pagesize         => "no description",
        publicipid       => "the public IP address id of the load balancer rule",
        virtualmachineid => "the ID of the virtual machine of the load balancer rule",
        zoneid           => "the availability zone ID",
      },
    },
    response => {
      account     => "the account of the load balancer rule",
      algorithm   => "the load balancer algorithm (source, roundrobin, leastconn)",
      cidrlist    => "the cidr list to forward traffic from",
      description => "the description of the load balancer",
      domain      => "the domain of the load balancer rule",
      domainid    => "the domain ID of the load balancer rule",
      id          => "the load balancer rule ID",
      name        => "the name of the load balancer",
      privateport => "the private port",
      publicip    => "the public ip address",
      publicipid  => "the public ip address id",
      publicport  => "the public port",
      state       => "the state of the rule",
      zoneid      => "the id of the zone the rule belongs to",
    },
    section => "LoadBalancer",
  },
  removeFromLoadBalancerRule => {
    description => "Removes a virtual machine or a list of virtual machines from a load balancer rule.",
    isAsync     => "true",
    level       => 15,
    request     => {
      required => {
        id => "The ID of the load balancer rule",
        virtualmachineids =>
            "the list of IDs of the virtual machines that are being removed from the load balancer rule (i.e. virtualMachineIds=1,2,3)",
      },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "LoadBalancer",
  },
  updateLoadBalancerRule => {
    description => "Updates load balancer",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        algorithm   => "load balancer algorithm (source, roundrobin, leastconn)",
        description => "the description of the load balancer rule",
        name        => "the name of the load balancer rule",
      },
      required => { id => "the id of the load balancer rule to update" },
    },
    response => {
      account     => "the account of the load balancer rule",
      algorithm   => "the load balancer algorithm (source, roundrobin, leastconn)",
      cidrlist    => "the cidr list to forward traffic from",
      description => "the description of the load balancer",
      domain      => "the domain of the load balancer rule",
      domainid    => "the domain ID of the load balancer rule",
      id          => "the load balancer rule ID",
      name        => "the name of the load balancer",
      privateport => "the private port",
      publicip    => "the public ip address",
      publicipid  => "the public ip address id",
      publicport  => "the public port",
      state       => "the state of the rule",
      zoneid      => "the id of the zone the rule belongs to",
    },
    section => "LoadBalancer",
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
$tests++;       # Test loading of LoadBalancer group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':LoadBalancer'; 1", 'use statement' ) } 'use took';
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
