##############################################################################
# This test file tests the functions found in the Usage section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  generateUsageRecords => {
    description => "Generates usage records",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => { domainid => "List events for the specified domain." },
      required => {
        enddate =>
            "End date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-03.",
        startdate =>
            "Start date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-01.",
      },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Usage",
  },
  listUsageRecords => {
    description => "Lists usage records for accounts",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        account   => "List usage records for the specified user.",
        accountid => "List usage records for the specified account",
        domainid  => "List usage records for the specified domain.",
        keyword   => "List by keyword",
        page      => "no description",
        pagesize  => "no description",
      },
      required => {
        enddate =>
            "End date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-03.",
        startdate =>
            "Start date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-01.",
      },
    },
    response => {
      account          => "the user account name",
      accountid        => "the user account Id",
      assigneddate     => "the assign date of the account",
      description      => "description of account, including account name, service offering, and template",
      domainid         => "the domain ID number",
      enddate          => "end date of account",
      ipaddress        => "the IP address",
      issourcenat      => "source Nat flag for IPAddress",
      name             => "virtual machine name",
      offeringid       => "service offering ID number",
      rawusage         => "raw usage in hours",
      releaseddate     => "the release date of the account",
      startdate        => "start date of account",
      templateid       => "template ID number",
      type             => "type",
      usage            => "usage in hours",
      usageid          => "id of the usage entity",
      usagetype        => "usage type",
      virtualmachineid => "virtual machine ID number",
      zoneid           => "the zone ID number",
    },
    section => "Usage",
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
$tests++;       # Test loading of Usage group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Usage'; 1", 'use statement' ) } 'use took';
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
