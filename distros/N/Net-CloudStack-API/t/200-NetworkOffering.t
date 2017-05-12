##############################################################################
# This test file tests the functions found in the NetworkOffering section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  listNetworkOfferings => {
    description => "Lists all available network offerings.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        availability => "the availability of network offering. Default value is Required",
        displaytext  => "list network offerings by display text",
        guestiptype  => "the guest ip type for the network offering, supported types are Direct and Virtual.",
        id           => "list network offerings by id",
        isdefault    => "true if need to list only default network offerings. Default value is false",
        isshared     => "true is network offering supports vlans",
        keyword      => "List by keyword",
        name         => "list network offerings by name",
        page         => "no description",
        pagesize     => "no description",
        specifyvlan  => "the tags for the network offering.",
        traffictype  => "list by traffic type",
        zoneid       => "list netowrk offerings available for network creation in specific zone",
      },
    },
    response => {
      availability   => "availability of the network offering",
      created        => "the date this network offering was created",
      displaytext    => "an alternate display text of the network offering.",
      guestiptype    => "guest ip type of the network offering",
      id             => "the id of the network offering",
      isdefault      => "true if network offering is default, false otherwise",
      maxconnections => "the max number of concurrent connection the network offering supports",
      name           => "the name of the network offering",
      networkrate    => "data transfer rate in megabits per second allowed.",
      specifyvlan    => "true if network offering supports vlans, false otherwise",
      tags           => "the tags for the network offering",
      traffictype =>
          "the traffic type for the network offering, supported types are Public, Management, Control, Guest, Vlan or Storage.",
    },
    section => "NetworkOffering",
  },
  updateNetworkOffering => {
    description => "Updates a network offering.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        availability =>
            "the availability of network offering. Default value is Required for Guest Virtual network offering; Optional for Guest Direct network offering",
        displaytext => "the display text of the network offering",
        id          => "the id of the network offering",
        name        => "the name of the network offering",
      },
    },
    response => {
      availability   => "availability of the network offering",
      created        => "the date this network offering was created",
      displaytext    => "an alternate display text of the network offering.",
      guestiptype    => "guest ip type of the network offering",
      id             => "the id of the network offering",
      isdefault      => "true if network offering is default, false otherwise",
      maxconnections => "the max number of concurrent connection the network offering supports",
      name           => "the name of the network offering",
      networkrate    => "data transfer rate in megabits per second allowed.",
      specifyvlan    => "true if network offering supports vlans, false otherwise",
      tags           => "the tags for the network offering",
      traffictype =>
          "the traffic type for the network offering, supported types are Public, Management, Control, Guest, Vlan or Storage.",
    },
    section => "NetworkOffering",
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
$tests++;       # Test loading of NetworkOffering group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':NetworkOffering'; 1", 'use statement' ) } 'use took';
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
