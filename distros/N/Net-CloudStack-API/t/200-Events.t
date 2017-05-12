##############################################################################
# This test file tests the functions found in the Events section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  listEvents => {
    description => "A command to list events.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "the account for the event. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID for the event. If used with the account parameter, returns all events for an account in the specified domain ID.",
        duration => "the duration of the event",
        enddate =>
            "the end date range of the list you want to retrieve (use format \"yyyy-MM-dd\" or the new format \"yyyy-MM-dd HH:mm:ss\")",
        entrytime => "the time the event was entered",
        id        => "the ID of the event",
        keyword   => "List by keyword",
        level     => "the event level (INFO, WARN, ERROR)",
        page      => "no description",
        pagesize  => "no description",
        startdate =>
            "the start date range of the list you want to retrieve (use format \"yyyy-MM-dd\" or the new format \"yyyy-MM-dd HH:mm:ss\")",
        type => "the event type (see event types)",
      },
    },
    response => {
      account =>
          "the account name for the account that owns the object being acted on in the event (e.g. the owner of the virtual machine, ip address, or security group)",
      created     => "the date the event was created",
      description => "a brief description of the event",
      domain      => "the name of the account's domain",
      domainid    => "the id of the account's domain",
      id          => "the ID of the event",
      level       => "the event level (INFO, WARN, ERROR)",
      parentid    => "whether the event is parented",
      state       => "the state of the event",
      type        => "the type of the event (see event types)",
      username =>
          "the name of the user who performed the action (can be different from the account if an admin is performing an action for a user, e.g. starting/stopping a user's virtual machine)",
    },
    section => "Events",
  },
  listEventTypes => {
    description => "List Event Types",
    isAsync     => "false",
    level       => 15,
    request     => undef,
    response    => { name => "Event Type" },
    section     => "Events",
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
$tests++;       # Test loading of Events group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Events'; 1", 'use statement' ) } 'use took';
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
