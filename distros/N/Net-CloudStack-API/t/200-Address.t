##############################################################################
# This test file tests the functions found in the Address section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  associateIpAddress => {
    description => "Acquires and associates a public IP to an account.",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        account   => "the account to associate with this IP address",
        domainid  => "the ID of the domain to associate with this IP address",
        networkid => "The network this ip address should be associated to.",
      },
      required => { zoneid => "the ID of the availability zone you want to acquire an public IP address from", },
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
    section => "Address",
  },
  disassociateIpAddress => {
    description => "Disassociates an ip address from the account.",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "the id of the public ip address to disassociate" }, },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Address",
  },
  listPublicIpAddresses => {
    description => "Lists all public ip addresses",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account       => "lists all public IP addresses by account. Must be used with the domainId parameter.",
        allocatedonly => "limits search results to allocated public IP addresses",
        domainid =>
            "lists all public IP addresses by domain ID. If used with the account parameter, lists all public IP addresses by account for specified domain.",
        forloadbalancing  => "list only ips used for load balancing",
        forvirtualnetwork => "the virtual network for the IP address",
        id                => "lists ip address by id",
        ipaddress         => "lists the specified IP address",
        keyword           => "List by keyword",
        page              => "no description",
        pagesize          => "no description",
        vlanid            => "lists all public IP addresses by VLAN ID",
        zoneid            => "lists all public IP addresses by Zone ID",
      },
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
    section => "Address",
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
$tests++;       # Test loading of Address group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Address'; 1", 'use statement' ) } 'use took';
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
