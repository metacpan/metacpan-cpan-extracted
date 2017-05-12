##############################################################################
# This test file tests the functions found in the User section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createUser => {
    description => "Creates a user for an account that already exists",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        domainid => "Creates the user under the specified domain. Has to be accompanied with the account parameter",
        timezone =>
            "Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.",
      },
      required => {
        account =>
            "Creates the user under the specified account. If no account is specified, the username will be used as the account name.",
        email     => "email",
        firstname => "firstname",
        lastname  => "lastname",
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
    section => "User",
  },
  deleteUser => {
    description => "Creates a user for an account",
    isAsync     => "false",
    level       => 3,
    request     => { required => { id => "Deletes a user" } },
    response    => {
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
    section => "User",
  },
  disableUser => {
    description => "Disables a user account",
    isAsync     => "true",
    level       => 7,
    request     => { required => { id => "Disables user by user ID." } },
    response    => {
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
    section => "User",
  },
  enableUser => {
    description => "Enables a user account",
    isAsync     => "false",
    level       => 7,
    request     => { required => { id => "Enables user by user ID." } },
    response    => {
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
    section => "User",
  },
  listUsers => {
    description => "Lists user accounts",
    isAsync     => "false",
    level       => 7,
    request     => {
      optional => {
        account     => "List user by account. Must be used with the domainId parameter.",
        accounttype => "List users by account type. Valid types include admin, domain-admin, read-only-admin, or user.",
        domainid =>
            "List all users in a domain. If used with the account parameter, lists an account in a specific domain.",
        id       => "List user by ID.",
        keyword  => "List by keyword",
        page     => "no description",
        pagesize => "no description",
        state    => "List users by state of the user account.",
        username => "List user by the username",
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
    section => "User",
  },
  updateUser => {
    description => "Updates a user account",
    isAsync     => "false",
    level       => 3,
    request     => {
      optional => {
        email     => "email",
        firstname => "first name",
        lastname  => "last name",
        password =>
            "Hashed password (default is MD5). If you wish to use any other hasing algorithm, you would need to write a custom authentication adapter",
        timezone =>
            "Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.",
        userapikey    => "The API key for the user. Must be specified with userSecretKey",
        username      => "Unique username",
        usersecretkey => "The secret key for the user. Must be specified with userApiKey",
      },
      required => { id => "User id" },
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
    section => "User",
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
$tests++;       # Test loading of User group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':User'; 1", 'use statement' ) } 'use took';
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
