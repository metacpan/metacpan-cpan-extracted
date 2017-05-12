##############################################################################
# This test file tests the functions found in the VLAN section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createVlanIpRange => {
    description => "Creates a VLAN IP range.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        account           => "account who will own the VLAN. If VLAN is Zone wide, this parameter should be ommited",
        domainid          => "domain ID of the account owning a VLAN",
        endip             => "the ending IP address in the VLAN IP range",
        forvirtualnetwork => "true if VLAN is of Virtual type, false if Direct",
        gateway           => "the gateway of the VLAN IP range",
        netmask           => "the netmask of the VLAN IP range",
        networkid         => "the network id",
        podid             => "optional parameter. Have to be specified for Direct Untagged vlan only.",
        vlan              => "the ID or VID of the VLAN. Default is an \"untagged\" VLAN.",
        zoneid            => "the Zone ID of the VLAN IP range",
      },
      required => { startip => "the beginning IP address in the VLAN IP range" },
    },
    response => {
      account           => "the account of the VLAN IP range",
      description       => "the description of the VLAN IP range",
      domain            => "the domain name of the VLAN IP range",
      domainid          => "the domain ID of the VLAN IP range",
      endip             => "the end ip of the VLAN IP range",
      forvirtualnetwork => "the virtual network for the VLAN IP range",
      gateway           => "the gateway of the VLAN IP range",
      id                => "the ID of the VLAN IP range",
      netmask           => "the netmask of the VLAN IP range",
      networkid         => "the network id of vlan range",
      podid             => "the Pod ID for the VLAN IP range",
      podname           => "the Pod name for the VLAN IP range",
      startip           => "the start ip of the VLAN IP range",
      vlan              => "the ID or VID of the VLAN.",
      zoneid            => "the Zone ID of the VLAN IP range",
    },
    section => "VLAN",
  },
  deleteVlanIpRange => {
    description => "Creates a VLAN IP range.",
    isAsync     => "false",
    level       => 1,
    request     => { required => { id => "the id of the VLAN IP range" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "VLAN",
  },
  listVlanIpRanges => {
    description => "Lists all VLAN IP ranges.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        account => "the account with which the VLAN IP range is associated. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID with which the VLAN IP range is associated.  If used with the account parameter, returns all VLAN IP ranges for that account in the specified domain.",
        forvirtualnetwork => "true if VLAN is of Virtual type, false if Direct",
        id                => "the ID of the VLAN IP range",
        keyword           => "List by keyword",
        networkid         => "network id of the VLAN IP range",
        page              => "no description",
        pagesize          => "no description",
        podid             => "the Pod ID of the VLAN IP range",
        vlan              => "the ID or VID of the VLAN. Default is an \"untagged\" VLAN.",
        zoneid            => "the Zone ID of the VLAN IP range",
      },
    },
    response => {
      account           => "the account of the VLAN IP range",
      description       => "the description of the VLAN IP range",
      domain            => "the domain name of the VLAN IP range",
      domainid          => "the domain ID of the VLAN IP range",
      endip             => "the end ip of the VLAN IP range",
      forvirtualnetwork => "the virtual network for the VLAN IP range",
      gateway           => "the gateway of the VLAN IP range",
      id                => "the ID of the VLAN IP range",
      netmask           => "the netmask of the VLAN IP range",
      networkid         => "the network id of vlan range",
      podid             => "the Pod ID for the VLAN IP range",
      podname           => "the Pod name for the VLAN IP range",
      startip           => "the start ip of the VLAN IP range",
      vlan              => "the ID or VID of the VLAN.",
      zoneid            => "the Zone ID of the VLAN IP range",
    },
    section => "VLAN",
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
$tests++;       # Test loading of VLAN group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':VLAN'; 1", 'use statement' ) } 'use took';
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
