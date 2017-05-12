##############################################################################
# This test file tests the functions found in the Domain section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createDomain => {
    description => "Creates a domain",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        networkdomain => "Network domain for networks in the domain",
        parentdomainid =>
            "assigns new domain a parent domain by domain ID of the parent.  If no parent domain is specied, the ROOT domain is assumed.",
      },
      required => { name => "creates domain with this name" },
    },
    response => {
      haschild         => "whether the domain has one or more sub-domains",
      id               => "the ID of the domain",
      level            => "the level of the domain",
      name             => "the name of the domain",
      networkdomain    => "the network domain",
      parentdomainid   => "the domain ID of the parent domain",
      parentdomainname => "the domain name of the parent domain",
      path             => "the path of the domain",
    },
    section => "Domain",
  },
  deleteDomain => {
    description => "Deletes a specified domain",
    isAsync     => "true",
    level       => 1,
    request     => {
      optional => {
        cleanup => "true if all domain resources (child domains, accounts) have to be cleaned up, false otherwise",
      },
      required => { id => "ID of domain to delete" },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Domain",
  },
  listDomainChildren => {
    description => "Lists all children domains belonging to a specified domain",
    isAsync     => "false",
    level       => 7,
    request     => {
      optional => {
        id => "list children domain by parent domain ID.",
        isrecursive =>
            "to return the entire tree, use the value \"true\". To return the first level children, use the value \"false\".",
        keyword  => "List by keyword",
        name     => "list children domains by name",
        page     => "no description",
        pagesize => "no description",
      },
    },
    response => {
      haschild         => "whether the domain has one or more sub-domains",
      id               => "the ID of the domain",
      level            => "the level of the domain",
      name             => "the name of the domain",
      networkdomain    => "the network domain",
      parentdomainid   => "the domain ID of the parent domain",
      parentdomainname => "the domain name of the parent domain",
      path             => "the path of the domain",
    },
    section => "Domain",
  },
  listDomains => {
    description => "Lists domains and provides detailed information for listed domains",
    isAsync     => "false",
    level       => 7,
    request     => {
      optional => {
        id       => "List domain by domain ID.",
        keyword  => "List by keyword",
        level    => "List domains by domain level.",
        name     => "List domain by domain name.",
        page     => "no description",
        pagesize => "no description",
      },
    },
    response => {
      haschild         => "whether the domain has one or more sub-domains",
      id               => "the ID of the domain",
      level            => "the level of the domain",
      name             => "the name of the domain",
      networkdomain    => "the network domain",
      parentdomainid   => "the domain ID of the parent domain",
      parentdomainname => "the domain name of the parent domain",
      path             => "the path of the domain",
    },
    section => "Domain",
  },
  updateDomain => {
    description => "Updates a domain with a new name",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional =>
          { name => "updates domain with this name", networkdomain => "Network domain for the domain's networks", },
      required => { id => "ID of domain to update" },
    },
    response => {
      haschild         => "whether the domain has one or more sub-domains",
      id               => "the ID of the domain",
      level            => "the level of the domain",
      name             => "the name of the domain",
      networkdomain    => "the network domain",
      parentdomainid   => "the domain ID of the parent domain",
      parentdomainname => "the domain name of the parent domain",
      path             => "the path of the domain",
    },
    section => "Domain",
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
$tests++;       # Test loading of Domain group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Domain'; 1", 'use statement' ) } 'use took';
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
