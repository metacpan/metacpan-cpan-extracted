##############################################################################
# This test file tests the functions found in the Network section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createNetwork => {
    description => "Creates a network",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account   => "account who will own the network",
        domainid  => "domain ID of the account owning a network",
        endip     => "the ending IP address in the network IP range. If not specified, will be defaulted to startIP",
        gateway   => "the gateway of the network",
        isdefault => "true if network is default, false otherwise",
        isshared  => "true is network is shared across accounts in the Zone",
        netmask   => "the netmask of the network",
        networkdomain => "network domain",
        startip       => "the beginning IP address in the network IP range",
        tags          => "Tag the network",
        vlan          => "the ID or VID of the network",
      },
      required => {
        displaytext       => "the display text of the network",
        name              => "the name of the network",
        networkofferingid => "the network offering id",
        zoneid            => "the Zone ID for the network",
      },
    },
    response => {
      "account"                     => "the owner of the network",
      "broadcastdomaintype"         => "Broadcast domain type of the network",
      "broadcasturi"                => "broadcast uri of the network",
      "displaytext"                 => "the displaytext of the network",
      "dns1"                        => "the first DNS for the network",
      "dns2"                        => "the second DNS for the network",
      "domain"                      => "the domain name of the network owner",
      "domainid"                    => "the domain id of the network owner",
      "endip"                       => "the end ip of the network",
      "gateway"                     => "the network's gateway",
      "id"                          => "the id of the network",
      "isdefault"                   => "true if network is default, false otherwise",
      "isshared"                    => "true if network is shared, false otherwise",
      "issystem"                    => "true if network is system, false otherwise",
      "name"                        => "the name of the network",
      "netmask"                     => "the network's netmask",
      "networkdomain"               => "the network domain",
      "networkofferingavailability" => "availability of the network offering the network is created from",
      "networkofferingdisplaytext"  => "display text of the network offering the network is created from",
      "networkofferingid"           => "network offering id the network is created from",
      "networkofferingname"         => "name of the network offering the network is created from",
      "related"                     => "related to what other network configuration",
      "securitygroupenabled"        => "true if security group is enabled, false otherwise",
      "service(*)"                  => "the list of services",
      "startip"                     => "the start ip of the network",
      "state"                       => "state of the network",
      "tags"                        => "comma separated tag",
      "traffictype"                 => "the traffic type of the network",
      "type"                        => "the type of the network",
      "vlan"                        => "the vlan of the network",
      "zoneid"                      => "zone id of the network",
    },
    section => "Network",
  },
  deleteNetwork => {
    description => "Deletes a network",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "the ID of the network" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Network",
  },
  listNetworks => {
    description => "Lists all available networks.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account     => "account who will own the VLAN. If VLAN is Zone wide, this parameter should be ommited",
        domainid    => "domain ID of the account owning a VLAN",
        id          => "list networks by id",
        isdefault   => "true if network is default, false otherwise",
        isshared    => "true if network is shared across accounts in the Zone, false otherwise",
        issystem    => "true if network is system, false otherwise",
        keyword     => "List by keyword",
        page        => "no description",
        pagesize    => "no description",
        traffictype => "type of the traffic",
        type        => "the type of the network",
        zoneid      => "the Zone ID of the network",
      },
    },
    response => {
      "account"                     => "the owner of the network",
      "broadcastdomaintype"         => "Broadcast domain type of the network",
      "broadcasturi"                => "broadcast uri of the network",
      "displaytext"                 => "the displaytext of the network",
      "dns1"                        => "the first DNS for the network",
      "dns2"                        => "the second DNS for the network",
      "domain"                      => "the domain name of the network owner",
      "domainid"                    => "the domain id of the network owner",
      "endip"                       => "the end ip of the network",
      "gateway"                     => "the network's gateway",
      "id"                          => "the id of the network",
      "isdefault"                   => "true if network is default, false otherwise",
      "isshared"                    => "true if network is shared, false otherwise",
      "issystem"                    => "true if network is system, false otherwise",
      "name"                        => "the name of the network",
      "netmask"                     => "the network's netmask",
      "networkdomain"               => "the network domain",
      "networkofferingavailability" => "availability of the network offering the network is created from",
      "networkofferingdisplaytext"  => "display text of the network offering the network is created from",
      "networkofferingid"           => "network offering id the network is created from",
      "networkofferingname"         => "name of the network offering the network is created from",
      "related"                     => "related to what other network configuration",
      "securitygroupenabled"        => "true if security group is enabled, false otherwise",
      "service(*)"                  => "the list of services",
      "startip"                     => "the start ip of the network",
      "state"                       => "state of the network",
      "tags"                        => "comma separated tag",
      "traffictype"                 => "the traffic type of the network",
      "type"                        => "the type of the network",
      "vlan"                        => "the vlan of the network",
      "zoneid"                      => "zone id of the network",
    },
    section => "Network",
  },
  restartNetwork => {
    description =>
        "Restarts the network; includes 1) restarting network elements - virtual routers, dhcp servers 2) reapplying all public ips 3) reapplying loadBalancing/portForwarding rules",
    isAsync => "true",
    level   => 15,
    request => {
      optional => { cleanup => "If cleanup old network elements" },
      required => { id      => "The id of the network to restart." },
    },
    response => {
      account             => "the account the public IP address is associated with",
      allocated           => "date the public IP address was acquired",
      associatednetworkid => "the ID of the Network associated with the IP address",
      domain              => "the domain the public IP address is associated with",
      domainid            => "the domain ID the public IP address is associated with",
      forvirtualnetwork   => "the virtual network for the IP address",
      id                  => "public IP address id",
      ipaddress           => "public IP address",
      issourcenat         => "true if the IP address is a source nat address, false otherwise",
      isstaticnat         => "true if this ip is for static nat, false otherwise",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume",
      jobstatus => "shows the current pending asynchronous job status",
      networkid => "the ID of the Network where ip belongs to",
      state     => "State of the ip address. Can be: Allocatin, Allocated and Releasing",
      virtualmachinedisplayname =>
          "virutal machine display name the ip address is assigned to (not null only for static nat Ip)",
      virtualmachineid   => "virutal machine id the ip address is assigned to (not null only for static nat Ip)",
      virtualmachinename => "virutal machine name the ip address is assigned to (not null only for static nat Ip)",
      vlanid             => "the ID of the VLAN associated with the IP address",
      vlanname           => "the VLAN associated with the IP address",
      zoneid             => "the ID of the zone the public IP address belongs to",
      zonename           => "the name of the zone the public IP address belongs to",
    },
    section => "Network",
  },
  updateNetwork => {
    description => "Updates a network",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        displaytext   => "the new display text for the network",
        name          => "the new name for the network",
        networkdomain => "network domain",
        tags          => "tags for the network",
      },
      required => { id => "the ID of the network" },
    },
    response => {
      "account"                     => "the owner of the network",
      "broadcastdomaintype"         => "Broadcast domain type of the network",
      "broadcasturi"                => "broadcast uri of the network",
      "displaytext"                 => "the displaytext of the network",
      "dns1"                        => "the first DNS for the network",
      "dns2"                        => "the second DNS for the network",
      "domain"                      => "the domain name of the network owner",
      "domainid"                    => "the domain id of the network owner",
      "endip"                       => "the end ip of the network",
      "gateway"                     => "the network's gateway",
      "id"                          => "the id of the network",
      "isdefault"                   => "true if network is default, false otherwise",
      "isshared"                    => "true if network is shared, false otherwise",
      "issystem"                    => "true if network is system, false otherwise",
      "name"                        => "the name of the network",
      "netmask"                     => "the network's netmask",
      "networkdomain"               => "the network domain",
      "networkofferingavailability" => "availability of the network offering the network is created from",
      "networkofferingdisplaytext"  => "display text of the network offering the network is created from",
      "networkofferingid"           => "network offering id the network is created from",
      "networkofferingname"         => "name of the network offering the network is created from",
      "related"                     => "related to what other network configuration",
      "securitygroupenabled"        => "true if security group is enabled, false otherwise",
      "service(*)"                  => "the list of services",
      "startip"                     => "the start ip of the network",
      "state"                       => "state of the network",
      "tags"                        => "comma separated tag",
      "traffictype"                 => "the traffic type of the network",
      "type"                        => "the type of the network",
      "vlan"                        => "the vlan of the network",
      "zoneid"                      => "zone id of the network",
    },
    section => "Network",
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
$tests++;       # Test loading of Network group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Network'; 1", 'use statement' ) } 'use took';
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
