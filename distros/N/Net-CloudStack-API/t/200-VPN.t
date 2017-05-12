##############################################################################
# This test file tests the functions found in the VPN section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  addVpnUser => {
    description => "Adds vpn users",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        account => "an optional account for the vpn user. Must be used with domainId.",
        domainid =>
            "an optional domainId for the vpn user. If the account parameter is used, domainId must also be used.",
      },
      required => { password => "password for the username", username => "username for the vpn user", },
    },
    response => {
      account    => "the account of the remote access vpn",
      domainid   => "the domain id of the account of the remote access vpn",
      domainname => "the domain name of the account of the remote access vpn",
      id         => "the vpn userID",
      username   => "the username of the vpn user",
    },
    section => "VPN",
  },
  createRemoteAccessVpn => {
    description => "Creates a l2tp/ipsec remote access vpn",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        account  => "an optional account for the VPN. Must be used with domainId.",
        domainid => "an optional domainId for the VPN. If the account parameter is used, domainId must also be used.",
        iprange =>
            "the range of ip addresses to allocate to vpn clients. The first ip in the range will be taken by the vpn server",
        openfirewall =>
            "if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default",
      },
      required => { publicipid => "public ip address id of the vpn server" },
    },
    response => {
      account      => "the account of the remote access vpn",
      domainid     => "the domain id of the account of the remote access vpn",
      domainname   => "the domain name of the account of the remote access vpn",
      iprange      => "the range of ips to allocate to the clients",
      presharedkey => "the ipsec preshared key",
      publicip     => "the public ip address of the vpn server",
      publicipid   => "the public ip address of the vpn server",
      state        => "the state of the rule",
    },
    section => "VPN",
  },
  deleteRemoteAccessVpn => {
    description => "Destroys a l2tp/ipsec remote access vpn",
    isAsync     => "true",
    level       => 15,
    request     => { required => { publicipid => "public ip address id of the vpn server" }, },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "VPN",
  },
  listRemoteAccessVpns => {
    description => "Lists remote access vpns",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "the account of the remote access vpn. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID of the remote access vpn rule. If used with the account parameter, lists remote access vpns for the account in the specified domain.",
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
      },
      required => { publicipid => "public ip address id of the vpn server" },
    },
    response => {
      account      => "the account of the remote access vpn",
      domainid     => "the domain id of the account of the remote access vpn",
      domainname   => "the domain name of the account of the remote access vpn",
      iprange      => "the range of ips to allocate to the clients",
      presharedkey => "the ipsec preshared key",
      publicip     => "the public ip address of the vpn server",
      publicipid   => "the public ip address of the vpn server",
      state        => "the state of the rule",
    },
    section => "VPN",
  },
  listVpnUsers => {
    description => "Lists vpn users",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "the account of the remote access vpn. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID of the remote access vpn. If used with the account parameter, lists remote access vpns for the account in the specified domain.",
        id       => "the ID of the vpn user",
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
        username => "the username of the vpn user.",
      },
    },
    response => {
      account    => "the account of the remote access vpn",
      domainid   => "the domain id of the account of the remote access vpn",
      domainname => "the domain name of the account of the remote access vpn",
      id         => "the vpn userID",
      username   => "the username of the vpn user",
    },
    section => "VPN",
  },
  removeVpnUser => {
    description => "Removes vpn user",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        account => "an optional account for the vpn user. Must be used with domainId.",
        domainid =>
            "an optional domainId for the vpn user. If the account parameter is used, domainId must also be used.",
      },
      required => { username => "username for the vpn user" },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "VPN",
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
$tests++;       # Test loading of VPN group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':VPN'; 1", 'use statement' ) } 'use took';
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
