##############################################################################
# This test file tests the functions found in the SystemVM section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  destroySystemVm => {
    description => "Destroyes a system virtual machine.",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "The ID of the system virtual machine" } },
    response    => {
      activeviewersessions => "the number of active console sessions for the console proxy system vm",
      created              => "the date and time the system VM was created",
      dns1                 => "the first DNS for the system VM",
      dns2                 => "the second DNS for the system VM",
      gateway              => "the gateway for the system VM",
      hostid               => "the host ID for the system VM",
      hostname             => "the hostname for the system VM",
      id                   => "the ID of the system VM",
      jobid =>
          "the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.",
      jobstatus =>
          "the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.",
      linklocalip         => "the link local IP address for the system vm",
      linklocalmacaddress => "the link local MAC address for the system vm",
      linklocalnetmask    => "the link local netmask for the system vm",
      name                => "the name of the system VM",
      networkdomain       => "the network domain for the system VM",
      podid               => "the Pod ID for the system VM",
      privateip           => "the private IP address for the system VM",
      privatemacaddress   => "the private MAC address for the system VM",
      privatenetmask      => "the private netmask for the system VM",
      publicip            => "the public IP address for the system VM",
      publicmacaddress    => "the public MAC address for the system VM",
      publicnetmask       => "the public netmask for the system VM",
      state               => "the state of the system VM",
      systemvmtype        => "the system VM type",
      templateid          => "the template ID for the system VM",
      zoneid              => "the Zone ID for the system VM",
      zonename            => "the Zone name for the system VM",
    },
    section => "SystemVM",
  },
  listSystemVms => {
    description => "List system virtual machines.",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        hostid       => "the host ID of the system VM",
        id           => "the ID of the system VM",
        keyword      => "List by keyword",
        name         => "the name of the system VM",
        page         => "no description",
        pagesize     => "no description",
        podid        => "the Pod ID of the system VM",
        state        => "the state of the system VM",
        systemvmtype => "the system VM type. Possible types are \"consoleproxy\" and \"secondarystoragevm\".",
        zoneid       => "the Zone ID of the system VM",
      },
    },
    response => {
      activeviewersessions => "the number of active console sessions for the console proxy system vm",
      created              => "the date and time the system VM was created",
      dns1                 => "the first DNS for the system VM",
      dns2                 => "the second DNS for the system VM",
      gateway              => "the gateway for the system VM",
      hostid               => "the host ID for the system VM",
      hostname             => "the hostname for the system VM",
      id                   => "the ID of the system VM",
      jobid =>
          "the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.",
      jobstatus =>
          "the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.",
      linklocalip         => "the link local IP address for the system vm",
      linklocalmacaddress => "the link local MAC address for the system vm",
      linklocalnetmask    => "the link local netmask for the system vm",
      name                => "the name of the system VM",
      networkdomain       => "the network domain for the system VM",
      podid               => "the Pod ID for the system VM",
      privateip           => "the private IP address for the system VM",
      privatemacaddress   => "the private MAC address for the system VM",
      privatenetmask      => "the private netmask for the system VM",
      publicip            => "the public IP address for the system VM",
      publicmacaddress    => "the public MAC address for the system VM",
      publicnetmask       => "the public netmask for the system VM",
      state               => "the state of the system VM",
      systemvmtype        => "the system VM type",
      templateid          => "the template ID for the system VM",
      zoneid              => "the Zone ID for the system VM",
      zonename            => "the Zone name for the system VM",
    },
    section => "SystemVM",
  },
  migrateSystemVm => {
    description => "Attempts Migration of a system virtual machine to the host specified.",
    isAsync     => "true",
    level       => 1,
    request     => {
      required =>
          { hostid => "destination Host ID to migrate VM to", virtualmachineid => "the ID of the virtual machine", },
    },
    response => {
      hostid       => "the host ID for the system VM",
      id           => "the ID of the system VM",
      name         => "the name of the system VM",
      role         => "the role of the system VM",
      state        => "the state of the system VM",
      systemvmtype => "the system VM type",
    },
    section => "SystemVM",
  },
  rebootSystemVm => {
    description => "Reboots a system VM.",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "The ID of the system virtual machine" } },
    response    => {
      activeviewersessions => "the number of active console sessions for the console proxy system vm",
      created              => "the date and time the system VM was created",
      dns1                 => "the first DNS for the system VM",
      dns2                 => "the second DNS for the system VM",
      gateway              => "the gateway for the system VM",
      hostid               => "the host ID for the system VM",
      hostname             => "the hostname for the system VM",
      id                   => "the ID of the system VM",
      jobid =>
          "the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.",
      jobstatus =>
          "the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.",
      linklocalip         => "the link local IP address for the system vm",
      linklocalmacaddress => "the link local MAC address for the system vm",
      linklocalnetmask    => "the link local netmask for the system vm",
      name                => "the name of the system VM",
      networkdomain       => "the network domain for the system VM",
      podid               => "the Pod ID for the system VM",
      privateip           => "the private IP address for the system VM",
      privatemacaddress   => "the private MAC address for the system VM",
      privatenetmask      => "the private netmask for the system VM",
      publicip            => "the public IP address for the system VM",
      publicmacaddress    => "the public MAC address for the system VM",
      publicnetmask       => "the public netmask for the system VM",
      state               => "the state of the system VM",
      systemvmtype        => "the system VM type",
      templateid          => "the template ID for the system VM",
      zoneid              => "the Zone ID for the system VM",
      zonename            => "the Zone name for the system VM",
    },
    section => "SystemVM",
  },
  startSystemVm => {
    description => "Starts a system virtual machine.",
    isAsync     => "true",
    level       => 1,
    request     => { required => { id => "The ID of the system virtual machine" } },
    response    => {
      activeviewersessions => "the number of active console sessions for the console proxy system vm",
      created              => "the date and time the system VM was created",
      dns1                 => "the first DNS for the system VM",
      dns2                 => "the second DNS for the system VM",
      gateway              => "the gateway for the system VM",
      hostid               => "the host ID for the system VM",
      hostname             => "the hostname for the system VM",
      id                   => "the ID of the system VM",
      jobid =>
          "the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.",
      jobstatus =>
          "the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.",
      linklocalip         => "the link local IP address for the system vm",
      linklocalmacaddress => "the link local MAC address for the system vm",
      linklocalnetmask    => "the link local netmask for the system vm",
      name                => "the name of the system VM",
      networkdomain       => "the network domain for the system VM",
      podid               => "the Pod ID for the system VM",
      privateip           => "the private IP address for the system VM",
      privatemacaddress   => "the private MAC address for the system VM",
      privatenetmask      => "the private netmask for the system VM",
      publicip            => "the public IP address for the system VM",
      publicmacaddress    => "the public MAC address for the system VM",
      publicnetmask       => "the public netmask for the system VM",
      state               => "the state of the system VM",
      systemvmtype        => "the system VM type",
      templateid          => "the template ID for the system VM",
      zoneid              => "the Zone ID for the system VM",
      zonename            => "the Zone name for the system VM",
    },
    section => "SystemVM",
  },
  stopSystemVm => {
    description => "Stops a system VM.",
    isAsync     => "true",
    level       => 1,
    request     => {
      optional => { forced => "Force stop the VM.  The caller knows the VM is stopped.", },
      required => { id     => "The ID of the system virtual machine" },
    },
    response => {
      activeviewersessions => "the number of active console sessions for the console proxy system vm",
      created              => "the date and time the system VM was created",
      dns1                 => "the first DNS for the system VM",
      dns2                 => "the second DNS for the system VM",
      gateway              => "the gateway for the system VM",
      hostid               => "the host ID for the system VM",
      hostname             => "the hostname for the system VM",
      id                   => "the ID of the system VM",
      jobid =>
          "the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.",
      jobstatus =>
          "the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.",
      linklocalip         => "the link local IP address for the system vm",
      linklocalmacaddress => "the link local MAC address for the system vm",
      linklocalnetmask    => "the link local netmask for the system vm",
      name                => "the name of the system VM",
      networkdomain       => "the network domain for the system VM",
      podid               => "the Pod ID for the system VM",
      privateip           => "the private IP address for the system VM",
      privatemacaddress   => "the private MAC address for the system VM",
      privatenetmask      => "the private netmask for the system VM",
      publicip            => "the public IP address for the system VM",
      publicmacaddress    => "the public MAC address for the system VM",
      publicnetmask       => "the public netmask for the system VM",
      state               => "the state of the system VM",
      systemvmtype        => "the system VM type",
      templateid          => "the template ID for the system VM",
      zoneid              => "the Zone ID for the system VM",
      zonename            => "the Zone name for the system VM",
    },
    section => "SystemVM",
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
$tests++;       # Test loading of SystemVM group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':SystemVM'; 1", 'use statement' ) } 'use took';
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
