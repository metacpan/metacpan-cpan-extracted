##############################################################################
# This test file tests the functions found in the Snapshot section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createSnapshot => {
    description => "Creates an instant snapshot of a volume.",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        account => "The account of the snapshot. The account parameter must be used with the domainId parameter.",
        domainid =>
            "The domain ID of the snapshot. If used with the account parameter, specifies a domain for the account associated with the disk volume.",
        policyid => "policy id of the snapshot, if this is null, then use MANUAL_POLICY.",
      },
      required => { volumeid => "The ID of the disk volume" },
    },
    response => {
      account      => "the account associated with the snapshot",
      created      => "the date the snapshot was created",
      domain       => "the domain name of the snapshot's account",
      domainid     => "the domain ID of the snapshot's account",
      id           => "ID of the snapshot",
      intervaltype => "valid types are hourly, daily, weekly, monthy, template, and none.",
      jobid =>
          "the job ID associated with the snapshot. This is only displayed if the snapshot listed is part of a currently running asynchronous job.",
      jobstatus =>
          "the job status associated with the snapshot.  This is only displayed if the snapshot listed is part of a currently running asynchronous job.",
      name         => "name of the snapshot",
      snapshottype => "the type of the snapshot",
      state =>
          "the state of the snapshot. BackedUp means that snapshot is ready to be used; Creating - the snapshot is being allocated on the primary storage; BackingUp - the snapshot is being backed up on secondary storage",
      volumeid   => "ID of the disk volume",
      volumename => "name of the disk volume",
      volumetype => "type of the disk volume",
    },
    section => "Snapshot",
  },
  createSnapshotPolicy => {
    description => "Creates a snapshot policy for the account.",
    isAsync     => "false",
    level       => 15,
    request     => {
      required => {
        intervaltype => "valid values are HOURLY, DAILY, WEEKLY, and MONTHLY",
        maxsnaps     => "maximum number of snapshots to retain",
        schedule =>
            "time the snapshot is scheduled to be taken. Format is:* if HOURLY, MM* if DAILY, MM:HH* if WEEKLY, MM:HH:DD (1-7)* if MONTHLY, MM:HH:DD (1-28)",
        timezone =>
            "Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.",
        volumeid => "the ID of the disk volume",
      },
    },
    response => {
      id           => "the ID of the snapshot policy",
      intervaltype => "the interval type of the snapshot policy",
      maxsnaps     => "maximum number of snapshots retained",
      schedule     => "time the snapshot is scheduled to be taken.",
      timezone     => "the time zone of the snapshot policy",
      volumeid     => "the ID of the disk volume",
    },
    section => "Snapshot",
  },
  deleteSnapshot => {
    description => "Deletes a snapshot of a disk volume.",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "The ID of the snapshot" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Snapshot",
  },
  deleteSnapshotPolicies => {
    description => "Deletes snapshot policies for the account.",
    isAsync     => "false",
    level       => 15,
    request  => { optional => { id => "the Id of the snapshot", ids => "list of snapshots IDs separated by comma", }, },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Snapshot",
  },
  listSnapshotPolicies => {
    description => "Lists snapshot policies.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "lists snapshot policies for the specified account. Must be used with domainid parameter.",
        domainid =>
            "the domain ID. If used with the account parameter, lists snapshot policies for the specified account in this domain.",
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
      },
      required => { volumeid => "the ID of the disk volume" },
    },
    response => {
      id           => "the ID of the snapshot policy",
      intervaltype => "the interval type of the snapshot policy",
      maxsnaps     => "maximum number of snapshots retained",
      schedule     => "time the snapshot is scheduled to be taken.",
      timezone     => "the time zone of the snapshot policy",
      volumeid     => "the ID of the disk volume",
    },
    section => "Snapshot",
  },
  listSnapshots => {
    description => "Lists all available snapshots for the account.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "lists snapshot belongig to the specified account. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID. If used with the account parameter, lists snapshots for the specified account in this domain.",
        id           => "lists snapshot by snapshot ID",
        intervaltype => "valid values are HOURLY, DAILY, WEEKLY, and MONTHLY.",
        isrecursive =>
            "defaults to false, but if true, lists all snapshots from the parent specified by the domain id till leaves.",
        keyword      => "List by keyword",
        name         => "lists snapshot by snapshot name",
        page         => "no description",
        pagesize     => "no description",
        snapshottype => "valid values are MANUAL or RECURRING.",
        volumeid     => "the ID of the disk volume",
      },
    },
    response => {
      account      => "the account associated with the snapshot",
      created      => "the date the snapshot was created",
      domain       => "the domain name of the snapshot's account",
      domainid     => "the domain ID of the snapshot's account",
      id           => "ID of the snapshot",
      intervaltype => "valid types are hourly, daily, weekly, monthy, template, and none.",
      jobid =>
          "the job ID associated with the snapshot. This is only displayed if the snapshot listed is part of a currently running asynchronous job.",
      jobstatus =>
          "the job status associated with the snapshot.  This is only displayed if the snapshot listed is part of a currently running asynchronous job.",
      name         => "name of the snapshot",
      snapshottype => "the type of the snapshot",
      state =>
          "the state of the snapshot. BackedUp means that snapshot is ready to be used; Creating - the snapshot is being allocated on the primary storage; BackingUp - the snapshot is being backed up on secondary storage",
      volumeid   => "ID of the disk volume",
      volumename => "name of the disk volume",
      volumetype => "type of the disk volume",
    },
    section => "Snapshot",
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
$tests++;       # Test loading of Snapshot group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Snapshot'; 1", 'use statement' ) } 'use took';
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
