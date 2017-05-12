##############################################################################
# This test file tests the functions found in the AsyncQuery section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  listAsyncJobs => {
    description => "Lists all pending asynchronous jobs for the account.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "the account associated with the async job. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID associated with the async job.  If used with the account parameter, returns async jobs for the account in the specified domain.",
        keyword   => "List by keyword",
        page      => "no description",
        pagesize  => "no description",
        startdate => "the start date of the async job",
      },
    },
    response => {
      accountid       => "the account that executed the async command",
      cmd             => "the async command executed",
      created         => "the created date of the job",
      jobid           => "async job ID",
      jobinstanceid   => "the unique ID of the instance/entity object related to the job",
      jobinstancetype => "the instance/entity object related to the job",
      jobprocstatus   => "the progress information of the PENDING job",
      jobresult       => "the result reason",
      jobresultcode   => "the result code for the job",
      jobresulttype   => "the result type",
      jobstatus       => "the current job status-should be 0 for PENDING",
      userid          => "the user that executed the async command",
    },
    section => "AsyncQuery",
  },
  queryAsyncJobResult => {
    description => "Retrieves the current status of asynchronous job.",
    isAsync     => "false",
    level       => 15,
    request     => { required => { jobid => "the ID of the asychronous job" } },
    response    => {
      accountid       => "the account that executed the async command",
      cmd             => "the async command executed",
      created         => "the created date of the job",
      jobid           => "async job ID",
      jobinstanceid   => "the unique ID of the instance/entity object related to the job",
      jobinstancetype => "the instance/entity object related to the job",
      jobprocstatus   => "the progress information of the PENDING job",
      jobresult       => "the result reason",
      jobresultcode   => "the result code for the job",
      jobresulttype   => "the result type",
      jobstatus       => "the current job status-should be 0 for PENDING",
      userid          => "the user that executed the async command",
    },
    section => "AsyncQuery",
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
$tests++;       # Test loading of AsyncQuery group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':AsyncQuery'; 1", 'use statement' ) } 'use took';
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
