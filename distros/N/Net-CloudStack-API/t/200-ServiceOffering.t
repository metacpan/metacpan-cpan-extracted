##############################################################################
# This test file tests the functions found in the ServiceOffering section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createServiceOffering => {
    description => "Creates a service offering.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        domainid    => "the ID of the containing domain, null for public offerings",
        hosttags    => "the host tag for this service offering.",
        issystem    => "is this a system vm offering",
        limitcpuuse => "restrict the CPU usage to committed service offering",
        networkrate =>
            "data transfer rate in megabits per second allowed. Supported only for non-System offering and system offerings having \"domainrouter\" systemvmtype",
        offerha     => "the HA for the service offering",
        storagetype => "the storage type of the service offering. Values are local and shared.",
        systemvmtype =>
            "the system VM type. Possible types are \"domainrouter\", \"consoleproxy\" and \"secondarystoragevm\".",
        tags => "the tags for this service offering.",
      },
      required => {
        cpunumber   => "the CPU number of the service offering",
        cpuspeed    => "the CPU speed of the service offering in MHz.",
        displaytext => "the display text of the service offering",
        memory      => "the total memory of the service offering in MB",
        name        => "the name of the service offering",
      },
    },
    response => {
      cpunumber    => "the number of CPU",
      cpuspeed     => "the clock rate CPU speed in Mhz",
      created      => "the date this service offering was created",
      defaultuse   => "is this a  default system vm offering",
      displaytext  => "an alternate display text of the service offering.",
      domain       => "Domain name for the offering",
      domainid     => "the domain id of the service offering",
      hosttags     => "the host tag for the service offering",
      id           => "the id of the service offering",
      issystem     => "is this a system vm offering",
      limitcpuuse  => "restrict the CPU usage to committed service offering",
      memory       => "the memory in MB",
      name         => "the name of the service offering",
      networkrate  => "data transfer rate in megabits per second allowed.",
      offerha      => "the ha support in the service offering",
      storagetype  => "the storage type for this service offering",
      systemvmtype => "is this a the systemvm type for system vm offering",
      tags         => "the tags for the service offering",
    },
    section => "ServiceOffering",
  },
  deleteServiceOffering => {
    description => "Deletes a service offering.",
    isAsync     => "false",
    level       => 1,
    request     => { required => { id => "the ID of the service offering" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "ServiceOffering",
  },
  listServiceOfferings => {
    description => "Lists all available service offerings.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        domainid => "the ID of the domain associated with the service offering",
        id       => "ID of the service offering",
        issystem => "is this a system vm offering",
        keyword  => "List by keyword",
        name     => "name of the service offering",
        page     => "no description",
        pagesize => "no description",
        systemvmtype =>
            "the system VM type. Possible types are \"consoleproxy\", \"secondarystoragevm\" or \"domainrouter\".",
        virtualmachineid =>
            "the ID of the virtual machine. Pass this in if you want to see the available service offering that a virtual machine can be changed to.",
      },
    },
    response => {
      cpunumber    => "the number of CPU",
      cpuspeed     => "the clock rate CPU speed in Mhz",
      created      => "the date this service offering was created",
      defaultuse   => "is this a  default system vm offering",
      displaytext  => "an alternate display text of the service offering.",
      domain       => "Domain name for the offering",
      domainid     => "the domain id of the service offering",
      hosttags     => "the host tag for the service offering",
      id           => "the id of the service offering",
      issystem     => "is this a system vm offering",
      limitcpuuse  => "restrict the CPU usage to committed service offering",
      memory       => "the memory in MB",
      name         => "the name of the service offering",
      networkrate  => "data transfer rate in megabits per second allowed.",
      offerha      => "the ha support in the service offering",
      storagetype  => "the storage type for this service offering",
      systemvmtype => "is this a the systemvm type for system vm offering",
      tags         => "the tags for the service offering",
    },
    section => "ServiceOffering",
  },
  updateServiceOffering => {
    description => "Updates a service offering.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        displaytext => "the display text of the service offering to be updated",
        name        => "the name of the service offering to be updated",
      },
      required => { id => "the ID of the service offering to be updated" },
    },
    response => {
      cpunumber    => "the number of CPU",
      cpuspeed     => "the clock rate CPU speed in Mhz",
      created      => "the date this service offering was created",
      defaultuse   => "is this a  default system vm offering",
      displaytext  => "an alternate display text of the service offering.",
      domain       => "Domain name for the offering",
      domainid     => "the domain id of the service offering",
      hosttags     => "the host tag for the service offering",
      id           => "the id of the service offering",
      issystem     => "is this a system vm offering",
      limitcpuuse  => "restrict the CPU usage to committed service offering",
      memory       => "the memory in MB",
      name         => "the name of the service offering",
      networkrate  => "data transfer rate in megabits per second allowed.",
      offerha      => "the ha support in the service offering",
      storagetype  => "the storage type for this service offering",
      systemvmtype => "is this a the systemvm type for system vm offering",
      tags         => "the tags for the service offering",
    },
    section => "ServiceOffering",
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
$tests++;       # Test loading of ServiceOffering group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':ServiceOffering'; 1", 'use statement' ) } 'use took';
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
