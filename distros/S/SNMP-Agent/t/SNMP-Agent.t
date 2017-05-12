use strict;
use warnings;
use Test::More tests => 5;
use NetSNMP::ASN qw/ASN_GAUGE ASN_OCTET_STR/;
use NetSNMP::OID;

require_ok( 'SNMP::Agent' );

sub handler_basic1 { return "forty-two" }
sub handler_basic2 { return 42 }
 
my $root_oid = '1.3.6.1.4.1.8072.9999.9999.123';
my %handlers = (
  '1' => { handler => \&handler_basic2 },     # default type ASN_OCTET_STR
  '2' => { handler => \&handler_basic1, type => ASN_GAUGE },
);
 
my $agent1 = new SNMP::Agent('my_agent', $root_oid, \%handlers);
BAIL_OUT("Cannot continue without SNMP::Agent object") unless(defined($agent1));

# Test _get_next_oid behaviour
my $oid1 = new NetSNMP::OID('1.2.3.4.5');
my $returned_next1 = $agent1->_get_next_oid($oid1);
is($returned_next1, undef, "default _get_next_oid undef");

sub handler_next { my $oid = join('.', ($_[0]->to_array(), '1')) }
$agent1->register_get_next_oid(\&handler_next);

my $next_oid = join('.', (new NetSNMP::OID('1.2.3.4.5.1'))->to_array());
my $returned_next2 = $agent1->_get_next_oid($oid1);
is($returned_next2, $next_oid, "_get_next_oid handler call");

# Test _get_asn_type behaviour
my $returned_asn1 = $agent1->_get_asn_type($oid1);
is($returned_asn1, undef, "default _get_asn_type handler undef");

sub handler_asn { return ASN_GAUGE }
$agent1->register_get_asn_type(\&handler_asn);

my $returned_asn2 = $agent1->_get_asn_type($oid1);
is($returned_asn2, ASN_GAUGE, "_get_asn_type handler call");
