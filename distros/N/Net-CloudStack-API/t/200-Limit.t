##############################################################################
# This test file tests the functions found in the Limit section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  listResourceLimits => {
    description => "Lists resource limits.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "Lists resource limits by account. Must be used with the domainId parameter.",
        domainid =>
            "Lists resource limits by domain ID. If used with the account parameter, lists resource limits for a specified account in a specified domain.",
        id       => "Lists resource limits by ID.",
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
        resourcetype =>
            "Type of resource to update. Values are 0, 1, 2, 3, and 4. 0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.",
      },
    },
    response => {
      account  => "the account of the resource limit",
      domain   => "the domain name of the resource limit",
      domainid => "the domain ID of the resource limit",
      max      => "the maximum number of the resource. A -1 means the resource currently has no limit.",
      resourcetype =>
          "resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.",
    },
    section => "Limit",
  },
  updateResourceCount => {
    description => "Recalculate and update resource count for an account or domain.",
    isAsync     => "false",
    level       => 7,
    request     => {
      optional => {
        account => "Update resource count for a specified account. Must be used with the domainId parameter.",
        resourcetype =>
            "Type of resource to update. If specifies valid values are 0, 1, 2, 3, and 4. If not specified will update all resource counts0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.",
      },
      required => {
        domainid =>
            "If account parameter specified then updates resource counts for a specified account in this domain else update resource counts for all accounts & child domains in specified domain.",
      },
    },
    response => {
      account       => "the account for which resource count's are updated",
      domain        => "the domain name for which resource count's are updated",
      domainid      => "the domain ID for which resource count's are updated",
      resourcecount => "resource count",
      resourcetype =>
          "resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.",
    },
    section => "Limit",
  },
  updateResourceLimit => {
    description => "Updates resource limits for an account or domain.",
    isAsync     => "false",
    level       => 7,
    request     => {
      optional => {
        account => "Update resource for a specified account. Must be used with the domainId parameter.",
        domainid =>
            "Update resource limits for all accounts in specified domain. If used with the account parameter, updates resource limits for a specified account in specified domain.",
        max => "Maximum resource limit.",
      },
      required => {
        resourcetype =>
            "Type of resource to update. Values are 0, 1, 2, 3, and 4. 0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.",
      },
    },
    response => {
      account  => "the account of the resource limit",
      domain   => "the domain name of the resource limit",
      domainid => "the domain ID of the resource limit",
      max      => "the maximum number of the resource. A -1 means the resource currently has no limit.",
      resourcetype =>
          "resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.",
    },
    section => "Limit",
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
$tests++;       # Test loading of Limit group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Limit'; 1", 'use statement' ) } 'use took';
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
