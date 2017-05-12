##############################################################################
# This test file tests the functions found in the Zone section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createZone => {
    description => "Creates a Zone.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        allocationstate      => "Allocation state of this Zone for allocation of new resources",
        dns2                 => "the second DNS for the Zone",
        domain               => "Network domain name for the networks in the zone",
        domainid             => "the ID of the containing domain, null for public zones",
        guestcidraddress     => "the guest CIDR address for the Zone",
        internaldns2         => "the second internal DNS for the Zone",
        securitygroupenabled => "true if network is security group enabled, false otherwise",
        vlan                 => "the VLAN for the Zone",
      },
      required => {
        dns1         => "the first DNS for the Zone",
        internaldns1 => "the first internal DNS for the Zone",
        name         => "the name of the Zone",
        networktype  => "network type of the zone, can be Basic or Advanced",
      },
    },
    response => {
      allocationstate       => "the allocation state of the cluster",
      description           => "Zone description",
      dhcpprovider          => "the dhcp Provider for the Zone",
      displaytext           => "the display text of the zone",
      dns1                  => "the first DNS for the Zone",
      dns2                  => "the second DNS for the Zone",
      domain                => "Network domain name for the networks in the zone",
      domainid              => "the ID of the containing domain, null for public zones",
      guestcidraddress      => "the guest CIDR address for the Zone",
      id                    => "Zone id",
      internaldns1          => "the first internal DNS for the Zone",
      internaldns2          => "the second internal DNS for the Zone",
      name                  => "Zone name",
      networktype           => "the network type of the zone; can be Basic or Advanced",
      securitygroupsenabled => "true if security groups support is enabled, false otherwise",
      vlan                  => "the vlan range of the zone",
      zonetoken             => "Zone Token",
    },
    section => "Zone",
  },
  deleteZone => {
    description => "Deletes a Zone.",
    isAsync     => "false",
    level       => 1,
    request     => { required => { id => "the ID of the Zone" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Zone",
  },
  listZones => {
    description => "Lists zones",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        available =>
            "true if you want to retrieve all available Zones. False if you only want to return the Zones from which you have at least one VM. Default is false.",
        domainid => "the ID of the domain associated with the zone",
        id       => "the ID of the zone",
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
      },
    },
    response => {
      allocationstate       => "the allocation state of the cluster",
      description           => "Zone description",
      dhcpprovider          => "the dhcp Provider for the Zone",
      displaytext           => "the display text of the zone",
      dns1                  => "the first DNS for the Zone",
      dns2                  => "the second DNS for the Zone",
      domain                => "Network domain name for the networks in the zone",
      domainid              => "the ID of the containing domain, null for public zones",
      guestcidraddress      => "the guest CIDR address for the Zone",
      id                    => "Zone id",
      internaldns1          => "the first internal DNS for the Zone",
      internaldns2          => "the second internal DNS for the Zone",
      name                  => "Zone name",
      networktype           => "the network type of the zone; can be Basic or Advanced",
      securitygroupsenabled => "true if security groups support is enabled, false otherwise",
      vlan                  => "the vlan range of the zone",
      zonetoken             => "Zone Token",
    },
    section => "Zone",
  },
  updateZone => {
    description => "Updates a Zone.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        allocationstate  => "Allocation state of this cluster for allocation of new resources",
        details          => "the details for the Zone",
        dhcpprovider     => "the dhcp Provider for the Zone",
        dns1             => "the first DNS for the Zone",
        dns2             => "the second DNS for the Zone",
        dnssearchorder   => "the dns search order list",
        domain           => "Network domain name for the networks in the zone",
        guestcidraddress => "the guest CIDR address for the Zone",
        internaldns1     => "the first internal DNS for the Zone",
        internaldns2     => "the second internal DNS for the Zone",
        ispublic         => "updates a private zone to public if set, but not vice-versa",
        name             => "the name of the Zone",
        vlan             => "the VLAN for the Zone",
      },
      required => { id => "the ID of the Zone" },
    },
    response => {
      allocationstate       => "the allocation state of the cluster",
      description           => "Zone description",
      dhcpprovider          => "the dhcp Provider for the Zone",
      displaytext           => "the display text of the zone",
      dns1                  => "the first DNS for the Zone",
      dns2                  => "the second DNS for the Zone",
      domain                => "Network domain name for the networks in the zone",
      domainid              => "the ID of the containing domain, null for public zones",
      guestcidraddress      => "the guest CIDR address for the Zone",
      id                    => "Zone id",
      internaldns1          => "the first internal DNS for the Zone",
      internaldns2          => "the second internal DNS for the Zone",
      name                  => "Zone name",
      networktype           => "the network type of the zone; can be Basic or Advanced",
      securitygroupsenabled => "true if security groups support is enabled, false otherwise",
      vlan                  => "the vlan range of the zone",
      zonetoken             => "Zone Token",
    },
    section => "Zone",
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
$tests++;       # Test loading of Zone group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Zone'; 1", 'use statement' ) } 'use took';
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
