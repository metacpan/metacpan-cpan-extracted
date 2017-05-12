##############################################################################
# This test file tests the functions found in the SecurityGroup section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  authorizeSecurityGroupIngress => {
    description => "Authorizes a particular ingress rule for this security group",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        account  => "an optional account for the virtual machine. Must be used with domainId.",
        cidrlist => "the cidr list associated",
        domainid =>
            "an optional domainId for the security group. If the account parameter is used, domainId must also be used.",
        endport               => "end port for this ingress rule",
        icmpcode              => "error code for this icmp message",
        icmptype              => "type of the icmp message being sent",
        protocol              => "TCP is default. UDP is the other supported protocol",
        securitygroupid       => "The ID of the security group. Mutually exclusive with securityGroupName parameter",
        securitygroupname     => "The name of the security group. Mutually exclusive with securityGroupName parameter",
        startport             => "start port for this ingress rule",
        usersecuritygrouplist => "user to security group mapping",
      },
    },
    response => {
      account           => "account owning the ingress rule",
      cidr              => "the CIDR notation for the base IP address of the ingress rule",
      endport           => "the ending IP of the ingress rule",
      icmpcode          => "the code for the ICMP message response",
      icmptype          => "the type of the ICMP message response",
      protocol          => "the protocol of the ingress rule",
      ruleid            => "the id of the ingress rule",
      securitygroupname => "security group name",
      startport         => "the starting IP of the ingress rule",
    },
    section => "SecurityGroup",
  },
  createSecurityGroup => {
    description => "Creates a security group",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account     => "an optional account for the security group. Must be used with domainId.",
        description => "the description of the security group",
        domainid =>
            "an optional domainId for the security group. If the account parameter is used, domainId must also be used.",
      },
      required => { name => "name of the security group" },
    },
    response => {
      "account"        => "the account owning the security group",
      "description"    => "the description of the security group",
      "domain"         => "the domain name of the security group",
      "domainid"       => "the domain ID of the security group",
      "id"             => "the ID of the security group",
      "ingressrule(*)" => "the list of ingress rules associated with the security group",
      "jobid" =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume",
      "jobstatus" => "shows the current pending asynchronous job status",
      "name"      => "the name of the security group",
    },
    section => "SecurityGroup",
  },
  deleteSecurityGroup => {
    description => "Deletes security group",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account  => "the account of the security group. Must be specified with domain ID",
        domainid => "the domain ID of account owning the security group",
        id       => "The ID of the security group. Mutually exclusive with name parameter",
        name     => "The ID of the security group. Mutually exclusive with id parameter",
      },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "SecurityGroup",
  },
  listSecurityGroups => {
    description => "Lists security groups",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "lists all available port security groups for the account. Must be used with domainID parameter",
        domainid =>
            "lists all available security groups for the domain ID. If used with the account parameter, lists all available security groups for the account in the specified domain ID.",
        id                => "list the security group by the id provided",
        keyword           => "List by keyword",
        page              => "no description",
        pagesize          => "no description",
        securitygroupname => "lists security groups by name",
        virtualmachineid  => "lists security groups by virtual machine id",
      },
    },
    response => {
      "account"        => "the account owning the security group",
      "description"    => "the description of the security group",
      "domain"         => "the domain name of the security group",
      "domainid"       => "the domain ID of the security group",
      "id"             => "the ID of the security group",
      "ingressrule(*)" => "the list of ingress rules associated with the security group",
      "jobid" =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume",
      "jobstatus" => "shows the current pending asynchronous job status",
      "name"      => "the name of the security group",
    },
    section => "SecurityGroup",
  },
  revokeSecurityGroupIngress => {
    description => "Deletes a particular ingress rule from this security group",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "The ID of the ingress rule" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "SecurityGroup",
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
$tests++;       # Test loading of SecurityGroup group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':SecurityGroup'; 1", 'use statement' ) } 'use took';
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
