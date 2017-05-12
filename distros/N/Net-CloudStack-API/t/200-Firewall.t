##############################################################################
# This test file tests the functions found in the Firewall section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createFirewallRule => {
    description => "Creates a firewall rule for a given ip address",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        cidrlist  => "the cidr list to forward traffic from",
        endport   => "the ending port of firewall rule",
        icmpcode  => "error code for this icmp message",
        icmptype  => "type of the icmp message being sent",
        startport => "the starting port of firewall rule",
      },
      required => {
        ipaddressid => "the IP address id of the port forwarding rule",
        protocol    => "the protocol for the firewall rule. Valid values are TCP/UDP/ICMP.",
      },
    },
    response => {
      cidrlist    => "the cidr list to forward traffic from",
      endport     => "the ending port of firewall rule's port range",
      icmpcode    => "error code for this icmp message",
      icmptype    => "type of the icmp message being sent",
      id          => "the ID of the firewall rule",
      ipaddress   => "the public ip address for the port forwarding rule",
      ipaddressid => "the public ip address id for the port forwarding rule",
      protocol    => "the protocol of the firewall rule",
      startport   => "the starting port of firewall rule's port range",
      state       => "the state of the rule",
    },
    section => "Firewall",
  },
  createPortForwardingRule => {
    description => "Creates a port forwarding rule",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        cidrlist => "the cidr list to forward traffic from",
        openfirewall =>
            "if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default",
        privateendport => "the ending port of port forwarding rule's private port range",
        publicendport  => "the ending port of port forwarding rule's private port range",
      },
      required => {
        ipaddressid      => "the IP address id of the port forwarding rule",
        privateport      => "the starting port of port forwarding rule's private port range",
        protocol         => "the protocol for the port fowarding rule. Valid values are TCP or UDP.",
        publicport       => "the starting port of port forwarding rule's public port range",
        virtualmachineid => "the ID of the virtual machine for the port forwarding rule",
      },
    },
    response => {
      cidrlist                  => "the cidr list to forward traffic from",
      id                        => "the ID of the port forwarding rule",
      ipaddress                 => "the public ip address for the port forwarding rule",
      ipaddressid               => "the public ip address id for the port forwarding rule",
      privateendport            => "the ending port of port forwarding rule's private port range",
      privateport               => "the starting port of port forwarding rule's private port range",
      protocol                  => "the protocol of the port forwarding rule",
      publicendport             => "the ending port of port forwarding rule's private port range",
      publicport                => "the starting port of port forwarding rule's public port range",
      state                     => "the state of the rule",
      virtualmachinedisplayname => "the VM display name for the port forwarding rule",
      virtualmachineid          => "the VM ID for the port forwarding rule",
      virtualmachinename        => "the VM name for the port forwarding rule",
    },
    section => "Firewall",
  },
  deleteFirewallRule => {
    description => "Deletes a firewall rule",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "the ID of the firewall rule" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Firewall",
  },
  deletePortForwardingRule => {
    description => "Deletes a port forwarding rule",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "the ID of the port forwarding rule" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Firewall",
  },
  listFirewallRules => {
    description => "Lists all firewall rules for an IP address.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "account. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID. If used with the account parameter, lists firewall rules for the specified account in this domain.",
        id          => "Lists rule with the specified ID.",
        ipaddressid => "the id of IP address of the firwall services",
        keyword     => "List by keyword",
        page        => "no description",
        pagesize    => "no description",
      },
    },
    response => {
      cidrlist    => "the cidr list to forward traffic from",
      endport     => "the ending port of firewall rule's port range",
      icmpcode    => "error code for this icmp message",
      icmptype    => "type of the icmp message being sent",
      id          => "the ID of the firewall rule",
      ipaddress   => "the public ip address for the port forwarding rule",
      ipaddressid => "the public ip address id for the port forwarding rule",
      protocol    => "the protocol of the firewall rule",
      startport   => "the starting port of firewall rule's port range",
      state       => "the state of the rule",
    },
    section => "Firewall",
  },
  listPortForwardingRules => {
    description => "Lists all port forwarding rules for an IP address.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "account. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID. If used with the account parameter, lists port forwarding rules for the specified account in this domain.",
        id          => "Lists rule with the specified ID.",
        ipaddressid => "the id of IP address of the port forwarding services",
        keyword     => "List by keyword",
        page        => "no description",
        pagesize    => "no description",
      },
    },
    response => {
      cidrlist                  => "the cidr list to forward traffic from",
      id                        => "the ID of the port forwarding rule",
      ipaddress                 => "the public ip address for the port forwarding rule",
      ipaddressid               => "the public ip address id for the port forwarding rule",
      privateendport            => "the ending port of port forwarding rule's private port range",
      privateport               => "the starting port of port forwarding rule's private port range",
      protocol                  => "the protocol of the port forwarding rule",
      publicendport             => "the ending port of port forwarding rule's private port range",
      publicport                => "the starting port of port forwarding rule's public port range",
      state                     => "the state of the rule",
      virtualmachinedisplayname => "the VM display name for the port forwarding rule",
      virtualmachineid          => "the VM ID for the port forwarding rule",
      virtualmachinename        => "the VM name for the port forwarding rule",
    },
    section => "Firewall",
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
$tests++;       # Test loading of Firewall group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Firewall'; 1", 'use statement' ) } 'use took';
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
