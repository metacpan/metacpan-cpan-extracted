##############################################################################
# This test file tests the functions found in the Account section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createAccount => {
    description => "Creates an account",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        account =>
            "Creates the user under the specified account. If no account is specified, the username will be used as the account name.",
        domainid      => "Creates the user under the specified domain.",
        networkdomain => "Network domain for the account's networks",
        timezone =>
            "Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.",
      },
      required => {
        accounttype => "Type of the account.  Specify 0 for user, 1 for root admin, and 2 for domain admin",
        email       => "email",
        firstname   => "firstname",
        lastname    => "lastname",
        password =>
            "Hashed password (Default is MD5). If you wish to use any other hashing algorithm, you would need to write a custom authentication adapter See Docs section.",
        username => "Unique username.",
      },
    },
    response => {
      account     => "the account name of the user",
      accounttype => "the account type of the user",
      apikey      => "the api key of the user",
      created     => "the date and time the user account was created",
      domain      => "the domain name of the user",
      domainid    => "the domain ID of the user",
      email       => "the user email address",
      firstname   => "the user firstname",
      id          => "the user ID",
      lastname    => "the user lastname",
      secretkey   => "the secret key of the user",
      state       => "the user state",
      timezone    => "the timezone user was created in",
      username    => "the user name",
    },
    section => "Account",
  },
  deleteAccount => {
    description => "Deletes a account, and all users associated with this account",
    isAsync     => "true",
    level       => 3,
    request     => { required => { id => "Account id" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Account",
  },
  disableAccount => {
    description => "Disables an account",
    isAsync     => "true",
    level       => 7,
    request     => {
      required => {
        account  => "Disables specified account.",
        domainid => "Disables specified account in this domain.",
        lock     => "If true, only lock the account; else disable the account",
      },
    },
    response => {
      "accounttype"       => "account type (admin, domain-admin, user)",
      "domain"            => "name of the Domain the account belongs too",
      "domainid"          => "id of the Domain the account belongs too",
      "id"                => "the id of the account",
      "ipavailable"       => "the total number of public ip addresses available for this account to acquire",
      "iplimit"           => "the total number of public ip addresses this account can acquire",
      "iptotal"           => "the total number of public ip addresses allocated for this account",
      "iscleanuprequired" => "true if the account requires cleanup",
      "name"              => "the name of the account",
      "networkdomain"     => "the network domain",
      "receivedbytes"     => "the total number of network traffic bytes received",
      "sentbytes"         => "the total number of network traffic bytes sent",
      "snapshotavailable" => "the total number of snapshots available for this account",
      "snapshotlimit"     => "the total number of snapshots which can be stored by this account",
      "snapshottotal"     => "the total number of snapshots stored by this account",
      "state"             => "the state of the account",
      "templateavailable" => "the total number of templates available to be created by this account",
      "templatelimit"     => "the total number of templates which can be created by this account",
      "templatetotal"     => "the total number of templates which have been created by this account",
      "user(*)"           => "the list of users associated with account",
      "vmavailable"       => "the total number of virtual machines available for this account to acquire",
      "vmlimit"           => "the total number of virtual machines that can be deployed by this account",
      "vmrunning"         => "the total number of virtual machines running for this account",
      "vmstopped"         => "the total number of virtual machines stopped for this account",
      "vmtotal"           => "the total number of virtual machines deployed by this account",
      "volumeavailable"   => "the total volume available for this account",
      "volumelimit"       => "the total volume which can be used by this account",
      "volumetotal"       => "the total volume being used by this account",
    },
    section => "Account",
  },
  enableAccount => {
    description => "Enables an account",
    isAsync     => "false",
    level       => 7,
    request     => {
      required => { account => "Enables specified account.", domainid => "Enables specified account in this domain.", },
    },
    response => {
      "accounttype"       => "account type (admin, domain-admin, user)",
      "domain"            => "name of the Domain the account belongs too",
      "domainid"          => "id of the Domain the account belongs too",
      "id"                => "the id of the account",
      "ipavailable"       => "the total number of public ip addresses available for this account to acquire",
      "iplimit"           => "the total number of public ip addresses this account can acquire",
      "iptotal"           => "the total number of public ip addresses allocated for this account",
      "iscleanuprequired" => "true if the account requires cleanup",
      "name"              => "the name of the account",
      "networkdomain"     => "the network domain",
      "receivedbytes"     => "the total number of network traffic bytes received",
      "sentbytes"         => "the total number of network traffic bytes sent",
      "snapshotavailable" => "the total number of snapshots available for this account",
      "snapshotlimit"     => "the total number of snapshots which can be stored by this account",
      "snapshottotal"     => "the total number of snapshots stored by this account",
      "state"             => "the state of the account",
      "templateavailable" => "the total number of templates available to be created by this account",
      "templatelimit"     => "the total number of templates which can be created by this account",
      "templatetotal"     => "the total number of templates which have been created by this account",
      "user(*)"           => "the list of users associated with account",
      "vmavailable"       => "the total number of virtual machines available for this account to acquire",
      "vmlimit"           => "the total number of virtual machines that can be deployed by this account",
      "vmrunning"         => "the total number of virtual machines running for this account",
      "vmstopped"         => "the total number of virtual machines stopped for this account",
      "vmtotal"           => "the total number of virtual machines deployed by this account",
      "volumeavailable"   => "the total volume available for this account",
      "volumelimit"       => "the total volume which can be used by this account",
      "volumetotal"       => "the total volume being used by this account",
    },
    section => "Account",
  },
  listAccounts => {
    description => "Lists accounts and provides detailed account information for listed accounts",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        accounttype =>
            "list accounts by account type. Valid account types are 1 (admin), 2 (domain-admin), and 0 (user).",
        domainid =>
            "list all accounts in specified domain. If used with the name parameter, retrieves account information for the account with specified name in specified domain.",
        id                => "list account by account ID",
        iscleanuprequired => "list accounts by cleanuprequred attribute (values are true or false)",
        isrecursive =>
            "defaults to false, but if true, lists all accounts from the parent specified by the domain id till leaves.",
        keyword  => "List by keyword",
        name     => "list account by account name",
        page     => "no description",
        pagesize => "no description",
        state    => "list accounts by state. Valid states are enabled, disabled, and locked.",
      },
    },
    response => {
      "accounttype"       => "account type (admin, domain-admin, user)",
      "domain"            => "name of the Domain the account belongs too",
      "domainid"          => "id of the Domain the account belongs too",
      "id"                => "the id of the account",
      "ipavailable"       => "the total number of public ip addresses available for this account to acquire",
      "iplimit"           => "the total number of public ip addresses this account can acquire",
      "iptotal"           => "the total number of public ip addresses allocated for this account",
      "iscleanuprequired" => "true if the account requires cleanup",
      "name"              => "the name of the account",
      "networkdomain"     => "the network domain",
      "receivedbytes"     => "the total number of network traffic bytes received",
      "sentbytes"         => "the total number of network traffic bytes sent",
      "snapshotavailable" => "the total number of snapshots available for this account",
      "snapshotlimit"     => "the total number of snapshots which can be stored by this account",
      "snapshottotal"     => "the total number of snapshots stored by this account",
      "state"             => "the state of the account",
      "templateavailable" => "the total number of templates available to be created by this account",
      "templatelimit"     => "the total number of templates which can be created by this account",
      "templatetotal"     => "the total number of templates which have been created by this account",
      "user(*)"           => "the list of users associated with account",
      "vmavailable"       => "the total number of virtual machines available for this account to acquire",
      "vmlimit"           => "the total number of virtual machines that can be deployed by this account",
      "vmrunning"         => "the total number of virtual machines running for this account",
      "vmstopped"         => "the total number of virtual machines stopped for this account",
      "vmtotal"           => "the total number of virtual machines deployed by this account",
      "volumeavailable"   => "the total volume available for this account",
      "volumelimit"       => "the total volume which can be used by this account",
      "volumetotal"       => "the total volume being used by this account",
    },
    section => "Account",
  },
  updateAccount => {
    description => "Updates account information for the authenticated user",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => { networkdomain => "Network domain for the account's networks" },
      required => {
        account  => "the current account name",
        domainid => "the ID of the domain where the account exists",
        newname  => "new name for the account",
      },
    },
    response => {
      "accounttype"       => "account type (admin, domain-admin, user)",
      "domain"            => "name of the Domain the account belongs too",
      "domainid"          => "id of the Domain the account belongs too",
      "id"                => "the id of the account",
      "ipavailable"       => "the total number of public ip addresses available for this account to acquire",
      "iplimit"           => "the total number of public ip addresses this account can acquire",
      "iptotal"           => "the total number of public ip addresses allocated for this account",
      "iscleanuprequired" => "true if the account requires cleanup",
      "name"              => "the name of the account",
      "networkdomain"     => "the network domain",
      "receivedbytes"     => "the total number of network traffic bytes received",
      "sentbytes"         => "the total number of network traffic bytes sent",
      "snapshotavailable" => "the total number of snapshots available for this account",
      "snapshotlimit"     => "the total number of snapshots which can be stored by this account",
      "snapshottotal"     => "the total number of snapshots stored by this account",
      "state"             => "the state of the account",
      "templateavailable" => "the total number of templates available to be created by this account",
      "templatelimit"     => "the total number of templates which can be created by this account",
      "templatetotal"     => "the total number of templates which have been created by this account",
      "user(*)"           => "the list of users associated with account",
      "vmavailable"       => "the total number of virtual machines available for this account to acquire",
      "vmlimit"           => "the total number of virtual machines that can be deployed by this account",
      "vmrunning"         => "the total number of virtual machines running for this account",
      "vmstopped"         => "the total number of virtual machines stopped for this account",
      "vmtotal"           => "the total number of virtual machines deployed by this account",
      "volumeavailable"   => "the total volume available for this account",
      "volumelimit"       => "the total volume which can be used by this account",
      "volumetotal"       => "the total volume being used by this account",
    },
    section => "Account",
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
$tests++;       # Test loading of Account group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Account'; 1", 'use statement' ) } 'use took';
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
