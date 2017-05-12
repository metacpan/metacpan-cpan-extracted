##############################################################################
# This test file tests the functions found in the VMGroup section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createInstanceGroup => {
    description => "Creates a vm group",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "the account of the instance group. The account parameter must be used with the domainId parameter.",
        domainid => "the domain ID of account owning the instance group",
      },
      required => { name => "the name of the instance group" },
    },
    response => {
      account  => "the account owning the instance group",
      created  => "time and date the instance group was created",
      domain   => "the domain name of the instance group",
      domainid => "the domain ID of the instance group",
      id       => "the id of the instance group",
      name     => "the name of the instance group",
    },
    section => "VMGroup",
  },
  deleteInstanceGroup => {
    description => "Deletes a vm group",
    isAsync     => "false",
    level       => 15,
    request     => { required => { id => "the ID of the instance group" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "VMGroup",
  },
  listInstanceGroups => {
    description => "Lists vm groups",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "list instance group belonging to the specified account. Must be used with domainid parameter",
        domainid =>
            "the domain ID. If used with the account parameter, lists virtual machines for the specified account in this domain.",
        id       => "list instance groups by ID",
        keyword  => "List by keyword",
        name     => "list instance groups by name",
        page     => "no description",
        pagesize => "no description",
      },
    },
    response => {
      account  => "the account owning the instance group",
      created  => "time and date the instance group was created",
      domain   => "the domain name of the instance group",
      domainid => "the domain ID of the instance group",
      id       => "the id of the instance group",
      name     => "the name of the instance group",
    },
    section => "VMGroup",
  },
  updateInstanceGroup => {
    description => "Updates a vm group",
    isAsync     => "false",
    level       => 15,
    request     => { optional => { name => "new instance group name" }, required => { id => "Instance group ID" }, },
    response    => {
      account  => "the account owning the instance group",
      created  => "time and date the instance group was created",
      domain   => "the domain name of the instance group",
      domainid => "the domain ID of the instance group",
      id       => "the id of the instance group",
      name     => "the name of the instance group",
    },
    section => "VMGroup",
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
$tests++;       # Test loading of VMGroup group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':VMGroup'; 1", 'use statement' ) } 'use took';
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
