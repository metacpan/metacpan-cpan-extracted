use strict;
use warnings;
use Test::More tests => 6;

use Net::SNMP qw(:asn1);
use Net::SNMP::Util qw(:all);
use Data::Dumper;

my ($r,$e,$s);

#diag( "Blocking object parameter pattern check" );

# -- 1 --
($r,$e) = snmpget();
ok(
    !$r && $e,
    "Negative: requiring essential argument"
);

# -- 2 --
$s = Net::SNMP->session();
($r,$e) = snmpget( hosts=>"moonlight", snmp=>$s, oids=>"1" );
ok(
    !$r,
    "Negative: 'hosts' exclusion against Net::SNMP 'snmp' instance"
);

# -- 3 --
($r,$e) = snmpget( hosts => { "dark" => undef, }, oids=>"1" );
ok(
    !$r && $e,
    "Negative: suitability of 'hosts'"
);

# -- 4 --
($r,$e) = snmpget( hosts => $s, oids=>"1" );
ok(
    !$r && $e,
    "Negative: suitability of 'hosts'"
);

# -- 5 --
undef $s;
$s = Net::SNMP->session( -nonblocking => 1 );
($r,$e) = snmpget( hosts => { "flower" => $s, }, oids=>"1" );
ok(
    defined($r) && $e,
    "Negative: Blocking exclusion against Non-bloking Net::SNMP instance of 'hosts'"
);

# -- 6 --
($r,$e) = snmpget( snmp =>$s, oids=>"1" );
ok(
    !$r && $e,
    "Negative: Blocking exclusion against Non-bloking Net::SNMP instance of 'snmp'"
);


