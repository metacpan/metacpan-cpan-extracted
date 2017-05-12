##############################################################################
# This test file tests the functions found in the Router section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  changeServiceForRouter => {
    description => "Upgrades domain router to a new service offering",
    isAsync     => "false",
    level       => 7,
    request     => {
      required => {
        id                => "The ID of the router",
        serviceofferingid => "the service offering ID to apply to the domain router",
      },
    },
    response => {
      account             => "the account associated with the router",
      created             => "the date and time the router was created",
      dns1                => "the first DNS for the router",
      dns2                => "the second DNS for the router",
      domain              => "the domain associated with the router",
      domainid            => "the domain ID associated with the router",
      gateway             => "the gateway for the router",
      guestipaddress      => "the guest IP address for the router",
      guestmacaddress     => "the guest MAC address for the router",
      guestnetmask        => "the guest netmask for the router",
      guestnetworkid      => "the ID of the corresponding guest network",
      hostid              => "the host ID for the router",
      hostname            => "the hostname for the router",
      id                  => "the id of the router",
      isredundantrouter   => "if this router is an redundant virtual router",
      linklocalip         => "the link local IP address for the router",
      linklocalmacaddress => "the link local MAC address for the router",
      linklocalnetmask    => "the link local netmask for the router",
      linklocalnetworkid  => "the ID of the corresponding link local network",
      name                => "the name of the router",
      networkdomain       => "the network domain for the router",
      podid               => "the Pod ID for the router",
      publicip            => "the public IP address for the router",
      publicmacaddress    => "the public MAC address for the router",
      publicnetmask       => "the public netmask for the router",
      publicnetworkid     => "the ID of the corresponding public network",
      redundantstate      => "the state of redundant virtual router",
      serviceofferingid   => "the ID of the service offering of the virtual machine",
      serviceofferingname => "the name of the service offering of the virtual machine",
      state               => "the state of the router",
      templateid          => "the template ID for the router",
      zoneid              => "the Zone ID for the router",
      zonename            => "the Zone name for the router",
    },
    section => "Router",
  },
  destroyRouter => {
    description => "Destroys a router.",
    isAsync     => "true",
    level       => 7,
    request     => { required => { id => "the ID of the router" } },
    response    => {
      account             => "the account associated with the router",
      created             => "the date and time the router was created",
      dns1                => "the first DNS for the router",
      dns2                => "the second DNS for the router",
      domain              => "the domain associated with the router",
      domainid            => "the domain ID associated with the router",
      gateway             => "the gateway for the router",
      guestipaddress      => "the guest IP address for the router",
      guestmacaddress     => "the guest MAC address for the router",
      guestnetmask        => "the guest netmask for the router",
      guestnetworkid      => "the ID of the corresponding guest network",
      hostid              => "the host ID for the router",
      hostname            => "the hostname for the router",
      id                  => "the id of the router",
      isredundantrouter   => "if this router is an redundant virtual router",
      linklocalip         => "the link local IP address for the router",
      linklocalmacaddress => "the link local MAC address for the router",
      linklocalnetmask    => "the link local netmask for the router",
      linklocalnetworkid  => "the ID of the corresponding link local network",
      name                => "the name of the router",
      networkdomain       => "the network domain for the router",
      podid               => "the Pod ID for the router",
      publicip            => "the public IP address for the router",
      publicmacaddress    => "the public MAC address for the router",
      publicnetmask       => "the public netmask for the router",
      publicnetworkid     => "the ID of the corresponding public network",
      redundantstate      => "the state of redundant virtual router",
      serviceofferingid   => "the ID of the service offering of the virtual machine",
      serviceofferingname => "the name of the service offering of the virtual machine",
      state               => "the state of the router",
      templateid          => "the template ID for the router",
      zoneid              => "the Zone ID for the router",
      zonename            => "the Zone name for the router",
    },
    section => "Router",
  },
  listRouters => {
    description => "List routers.",
    isAsync     => "false",
    level       => 7,
    request     => {
      optional => {
        account => "the name of the account associated with the router. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID associated with the router. If used with the account parameter, lists all routers associated with an account in the specified domain.",
        hostid    => "the host ID of the router",
        id        => "the ID of the disk router",
        keyword   => "List by keyword",
        name      => "the name of the router",
        networkid => "list by network id",
        page      => "no description",
        pagesize  => "no description",
        podid     => "the Pod ID of the router",
        state     => "the state of the router",
        zoneid    => "the Zone ID of the router",
      },
    },
    response => {
      account             => "the account associated with the router",
      created             => "the date and time the router was created",
      dns1                => "the first DNS for the router",
      dns2                => "the second DNS for the router",
      domain              => "the domain associated with the router",
      domainid            => "the domain ID associated with the router",
      gateway             => "the gateway for the router",
      guestipaddress      => "the guest IP address for the router",
      guestmacaddress     => "the guest MAC address for the router",
      guestnetmask        => "the guest netmask for the router",
      guestnetworkid      => "the ID of the corresponding guest network",
      hostid              => "the host ID for the router",
      hostname            => "the hostname for the router",
      id                  => "the id of the router",
      isredundantrouter   => "if this router is an redundant virtual router",
      linklocalip         => "the link local IP address for the router",
      linklocalmacaddress => "the link local MAC address for the router",
      linklocalnetmask    => "the link local netmask for the router",
      linklocalnetworkid  => "the ID of the corresponding link local network",
      name                => "the name of the router",
      networkdomain       => "the network domain for the router",
      podid               => "the Pod ID for the router",
      publicip            => "the public IP address for the router",
      publicmacaddress    => "the public MAC address for the router",
      publicnetmask       => "the public netmask for the router",
      publicnetworkid     => "the ID of the corresponding public network",
      redundantstate      => "the state of redundant virtual router",
      serviceofferingid   => "the ID of the service offering of the virtual machine",
      serviceofferingname => "the name of the service offering of the virtual machine",
      state               => "the state of the router",
      templateid          => "the template ID for the router",
      zoneid              => "the Zone ID for the router",
      zonename            => "the Zone name for the router",
    },
    section => "Router",
  },
  rebootRouter => {
    description => "Starts a router.",
    isAsync     => "true",
    level       => 7,
    request     => { required => { id => "the ID of the router" } },
    response    => {
      account             => "the account associated with the router",
      created             => "the date and time the router was created",
      dns1                => "the first DNS for the router",
      dns2                => "the second DNS for the router",
      domain              => "the domain associated with the router",
      domainid            => "the domain ID associated with the router",
      gateway             => "the gateway for the router",
      guestipaddress      => "the guest IP address for the router",
      guestmacaddress     => "the guest MAC address for the router",
      guestnetmask        => "the guest netmask for the router",
      guestnetworkid      => "the ID of the corresponding guest network",
      hostid              => "the host ID for the router",
      hostname            => "the hostname for the router",
      id                  => "the id of the router",
      isredundantrouter   => "if this router is an redundant virtual router",
      linklocalip         => "the link local IP address for the router",
      linklocalmacaddress => "the link local MAC address for the router",
      linklocalnetmask    => "the link local netmask for the router",
      linklocalnetworkid  => "the ID of the corresponding link local network",
      name                => "the name of the router",
      networkdomain       => "the network domain for the router",
      podid               => "the Pod ID for the router",
      publicip            => "the public IP address for the router",
      publicmacaddress    => "the public MAC address for the router",
      publicnetmask       => "the public netmask for the router",
      publicnetworkid     => "the ID of the corresponding public network",
      redundantstate      => "the state of redundant virtual router",
      serviceofferingid   => "the ID of the service offering of the virtual machine",
      serviceofferingname => "the name of the service offering of the virtual machine",
      state               => "the state of the router",
      templateid          => "the template ID for the router",
      zoneid              => "the Zone ID for the router",
      zonename            => "the Zone name for the router",
    },
    section => "Router",
  },
  startRouter => {
    description => "Starts a router.",
    isAsync     => "true",
    level       => 7,
    request     => { required => { id => "the ID of the router" } },
    response    => {
      account             => "the account associated with the router",
      created             => "the date and time the router was created",
      dns1                => "the first DNS for the router",
      dns2                => "the second DNS for the router",
      domain              => "the domain associated with the router",
      domainid            => "the domain ID associated with the router",
      gateway             => "the gateway for the router",
      guestipaddress      => "the guest IP address for the router",
      guestmacaddress     => "the guest MAC address for the router",
      guestnetmask        => "the guest netmask for the router",
      guestnetworkid      => "the ID of the corresponding guest network",
      hostid              => "the host ID for the router",
      hostname            => "the hostname for the router",
      id                  => "the id of the router",
      isredundantrouter   => "if this router is an redundant virtual router",
      linklocalip         => "the link local IP address for the router",
      linklocalmacaddress => "the link local MAC address for the router",
      linklocalnetmask    => "the link local netmask for the router",
      linklocalnetworkid  => "the ID of the corresponding link local network",
      name                => "the name of the router",
      networkdomain       => "the network domain for the router",
      podid               => "the Pod ID for the router",
      publicip            => "the public IP address for the router",
      publicmacaddress    => "the public MAC address for the router",
      publicnetmask       => "the public netmask for the router",
      publicnetworkid     => "the ID of the corresponding public network",
      redundantstate      => "the state of redundant virtual router",
      serviceofferingid   => "the ID of the service offering of the virtual machine",
      serviceofferingname => "the name of the service offering of the virtual machine",
      state               => "the state of the router",
      templateid          => "the template ID for the router",
      zoneid              => "the Zone ID for the router",
      zonename            => "the Zone name for the router",
    },
    section => "Router",
  },
  stopRouter => {
    description => "Stops a router.",
    isAsync     => "true",
    level       => 7,
    request     => {
      optional => { forced => "Force stop the VM. The caller knows the VM is stopped.", },
      required => { id     => "the ID of the router" },
    },
    response => {
      account             => "the account associated with the router",
      created             => "the date and time the router was created",
      dns1                => "the first DNS for the router",
      dns2                => "the second DNS for the router",
      domain              => "the domain associated with the router",
      domainid            => "the domain ID associated with the router",
      gateway             => "the gateway for the router",
      guestipaddress      => "the guest IP address for the router",
      guestmacaddress     => "the guest MAC address for the router",
      guestnetmask        => "the guest netmask for the router",
      guestnetworkid      => "the ID of the corresponding guest network",
      hostid              => "the host ID for the router",
      hostname            => "the hostname for the router",
      id                  => "the id of the router",
      isredundantrouter   => "if this router is an redundant virtual router",
      linklocalip         => "the link local IP address for the router",
      linklocalmacaddress => "the link local MAC address for the router",
      linklocalnetmask    => "the link local netmask for the router",
      linklocalnetworkid  => "the ID of the corresponding link local network",
      name                => "the name of the router",
      networkdomain       => "the network domain for the router",
      podid               => "the Pod ID for the router",
      publicip            => "the public IP address for the router",
      publicmacaddress    => "the public MAC address for the router",
      publicnetmask       => "the public netmask for the router",
      publicnetworkid     => "the ID of the corresponding public network",
      redundantstate      => "the state of redundant virtual router",
      serviceofferingid   => "the ID of the service offering of the virtual machine",
      serviceofferingname => "the name of the service offering of the virtual machine",
      state               => "the state of the router",
      templateid          => "the template ID for the router",
      zoneid              => "the Zone ID for the router",
      zonename            => "the Zone name for the router",
    },
    section => "Router",
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
$tests++;       # Test loading of Router group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Router'; 1", 'use statement' ) } 'use took';
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
