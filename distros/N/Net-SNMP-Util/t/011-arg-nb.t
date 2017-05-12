use strict;
use warnings;
use Test::More tests => 6;

use Net::SNMP qw(:asn1);
use Net::SNMP::Util qw(:all);
use Data::Dumper;

my ($r,$e,$s);

#diag( "# NonBlocking object parameter pattern check" );

# -- 1 --
($r,$e) = snmpparaget();
ok(
    !$r && $e,
    "Negative: requiring essential argument"
);

# -- 2 --
$s = Net::SNMP->session( -nonblocking=>1 );
($r,$e) = snmpparaget( hosts => "moonlight", snmp=>$s, oids=>"1" );
ok(
    !$r,
    "Negative: 'hosts' exclusion against Net::SNMP 'snmp' instance"
);

# -- 3 --
($r,$e) = snmpparaget( hosts => { "dark" => undef, }, oids=>"1" );
ok(
    !$r && $e,
    "Negative: suitability of 'hosts'"
);

# -- 4 --
($r,$e) = snmpparaget( hosts => $s, oids=>"1" );
ok(
    !$r && $e,
    "Negative: suitability of 'hosts'"
);

# -- 5 --
undef $s;
$s = Net::SNMP->session( -nonblocking => 0 );
($r,$e) = snmpparaget( hosts => { "flower" => $s, }, oids=>"1" );
ok(
    defined($r) && $e,
    "Negative: NonBlocking exclusion against Bloking Net::SNMP instance of 'hosts'"
);

# -- 6 --
($r,$e) = snmpparaget( snmp =>$s, oids=>"1" );
ok(
    !$r && $e,
    "Negative: NonBlocking exclusion against Bloking Net::SNMP instance of 'snmp'"
);


