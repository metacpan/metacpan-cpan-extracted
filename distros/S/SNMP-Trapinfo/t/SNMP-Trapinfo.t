# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SNMP-Trapinfo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 100;
BEGIN { use_ok('SNMP::Trapinfo') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use File::Temp qw(tempfile);
use Safe;

my $result;

my $fh = tempfile();

print $fh <<EOF;
cisco2611.lon.altinity
192.168.10.20
SNMPv2-MIB::sysUpTime.0 9:16:47:53.80
SNMPv2-MIB::snmpTrapOID.0 IF-MIB::linkUp.1
IF-MIB::ifIndex.2 2
IF-MIB::ifDescr.2 Serial0/0
IF-MIB::ifType.2 ppp
SNMPv2-SMI::enterprises.9.2.2.1.1.20.2 "PPP LCP Open"
SNMP-COMMUNITY-MIB::snmpTrapAddress.0 192.168.10.20
SNMP-COMMUNITY-MIB::snmpTrapCommunity.0 "public"
SNMPv2-MIB::snmpTrapEnterprise.0 SNMPv2-SMI::enterprises.9.1.186
0 0
#---next trap---#
cisco2620.lon.altinity
192.168.10.30
SNMPv2-MIB::sysUpTime.0 9:16:47:53.80
SNMPv2-MIB::snmpTrapOID.0 IF-MIB::linkUp.1
IF-MIB::ifIndex.2 12
IF-MIB::ifDescr.2 Serial0/0
IF-MIB::ifType.2 ppp
DUMMY::THING.0 With some data over multiple
lines for me
DUMMY::ANOTHER Again, but this time end with linefeed

DUMMY::YIKES prove this is read
EOF
seek ($fh, 0, 0);

my $trap = SNMP::Trapinfo->new(*$fh);
isa_ok( $trap, "SNMP::Trapinfo");

cmp_ok( $trap->hostname, 'eq', "cisco2611.lon.altinity", "Host name parsed correctly");
cmp_ok( $trap->hostip, 'eq', "192.168.10.20", "Host ip parsed correctly");
cmp_ok( $trap->trapname, 'eq', "IF-MIB::linkUp.1", "trapname correct");
cmp_ok( $trap->fully_translated, '==', 0, "trapname is not fully translated");
cmp_ok( $trap->data->{"SNMPv2-SMI::enterprises.9.2.2.1.1.20.2"}, 'eq', '"PPP LCP Open"', "Parse spaces correctly");
cmp_ok( $trap->expand('${SNMPv2-SMI::enterprises.9.2.2.1.1.20.2}'), 'eq', '"PPP LCP Open"', "And can reference it with a macro");
cmp_ok( $trap->P(3), 'eq', "sysUpTime", "Got p3 correctly");
cmp_ok( $trap->P(9), 'eq', "snmpTrapAddress", "Got p9 correctly");
cmp_ok( $trap->V(5), '==', 2, "Got v5 correctly");
cmp_ok( $trap->V(8), 'eq', '"PPP LCP Open"', "Got v8 correctly");
    is( $trap->V(13), '', "No V13 - got blank");
    is( $trap->P(25), '', "No P25 - got blank");
    is( $trap->V(12), '0', "Got a zero for V correctly");
    is( $trap->P(12), '0', "Got a zero for P correctly");
cmp_ok( $trap->expand('Port ${IF-MIB::ifIndex} (${P7}=${V7}) is Up with message ${V8}'), 'eq', 
	'Port 2 (ifType=ppp) is Up with message "PPP LCP Open"', "Macro expansion as expected");
cmp_ok( $trap->eval('"${IF-MIB::ifType}" eq "ppp" && ${IF-MIB::ifIndex} < 5'), 
	"eq", 1, "Got true eval");
cmp_ok( $trap->last_eval_string, 'eq', '"ppp" eq "ppp" && 2 < 5', "last_eval_string set");
    ok( ! defined $trap->eval('${IF-MIB::ifType} eq "ppp" && ${IF-MIB::ifIndex} < 5'), "Got eval failure");
cmp_ok( $trap->last_eval_string, 'eq', 'ppp eq "ppp" && 2 < 5', "last_eval_string set");
  like( $@, '/Bareword "ppp" not allowed while "strict subs" in use/', "Got eval error in \$@");
cmp_ok( $trap->eval('"${IF-MIB::ifType}" eq "ppp" && ${IF-MIB::ifIndex} == 5'), 
	"eq", 0, "Got false eval");
cmp_ok( $trap->last_eval_string, 'eq', '"ppp" eq "ppp" && 2 == 5', "last_eval_string set");
cmp_ok( $trap->eval("2"), '==', 1, "Got 1 for true");
    ok( $trap->eval('${SNMPv2-SMI::enterprises.9.2.2.1.1.20.2} =~ /Open/'), "Can do regexp");
cmp_ok( $trap->last_eval_string, 'eq', '"PPP LCP Open" =~ /Open/', "last_eval_string set");

my $expected = 'cisco2611.lon.altinity
192.168.10.20
SNMPv2-MIB::sysUpTime.0 9:16:47:53.80
SNMPv2-MIB::snmpTrapOID.0 IF-MIB::linkUp.1
IF-MIB::ifIndex.2 2
IF-MIB::ifDescr.2 Serial0/0
IF-MIB::ifType.2 ppp
SNMPv2-SMI::enterprises.9.2.2.1.1.20.2 "PPP LCP Open"
SNMP-COMMUNITY-MIB::snmpTrapAddress.0 192.168.10.20
SNMP-COMMUNITY-MIB::snmpTrapCommunity.0 "*****"
SNMPv2-MIB::snmpTrapEnterprise.0 SNMPv2-SMI::enterprises.9.1.186
0 0';
cmp_ok( $trap->packet( {hide_passwords=>1} ), 'eq', $expected, "Got full packet with passwords hidden");

$trap = SNMP::Trapinfo->new(*$fh);
cmp_ok( $trap->hostname, 'eq', "cisco2620.lon.altinity", "Host name parsed correctly for subsequent packet");
is( $trap->expand('${DUMMY::THING}'), "With some data over multiple", "Able to read values over multiple lines" );
is( $trap->expand('${P8}'), "THING", "Parameter name right");
is( $trap->expand('${V8}'), "With some data over multiple", "Right value too");
TODO: {
	# Need to investigate RFC to see if this is true
	local $TODO = "Possibly should get stricter with key format - look for ':'?";
	is( $trap->expand('${P9}'), "(null)", "No P9 because wrong format");
}
is( $trap->expand('${DUMMY::ANOTHER}'), "Again, but this time end with linefeed", "Able to read value when terminated with linefeed");
is( $trap->expand('${P10}'), "ANOTHER", "Parameter name right");
is( $trap->expand('${V10}'), "Again, but this time end with linefeed", "Right value too");
is( $trap->expand('${P11} ${V11}'), "(null) (null)", "No value set as format wrong");
is( $trap->expand('${DUMMY::YIKES}'), "prove this is read", "Continues reading");
is( $trap->expand('${P12}'), "YIKES", "Parameter name right");
is( $trap->expand('${V12}'), "prove this is read", "Right value too");

$expected = 'cisco2620.lon.altinity
192.168.10.30
SNMPv2-MIB::sysUpTime.0 9:16:47:53.80
SNMPv2-MIB::snmpTrapOID.0 IF-MIB::linkUp.1
IF-MIB::ifIndex.2 12
IF-MIB::ifDescr.2 Serial0/0
IF-MIB::ifType.2 ppp
DUMMY::THING.0 With some data over multiple
lines for me
DUMMY::ANOTHER Again, but this time end with linefeed

DUMMY::YIKES prove this is read';
cmp_ok( $trap->packet, 'eq', $expected, "Got full packet without passwords hidden");

ok( ! defined SNMP::Trapinfo->new(*$fh), "No more packets");

eval '$trap = SNMP::Trapinfo->new';
cmp_ok( $@, 'ne',"", "Complain if no parameters specified for new()");

my $data = <<EOF;
cisco9999.lon.altinity
UDP: [192.168.10.21]:3656
SNMPv2-MIB::sysUpTime.0 75:22:57:17.87
SNMPv2-MIB::snmpTrapOID.0 IF-MIB::linkDown
IF-MIB::ifIndex.24 24
IF-MIB::ifDescr.24 FastEthernet0/24
IF-MIB::ifType.24   ethernetCsmacd  
error
error_with_spaces_at_end     
SNMP-COMMUNITY-MIB::snmpTrapAddress.0 192.168.10.21
SNMP-COMMUNITY-MIB::snmpTrapCommunity.0 "public"
EOF

eval '$trap = SNMP::Trapinfo->new($data)';
like( $@, '/Bad ref/', "Complain if bad parameters for new()");

$trap = SNMP::Trapinfo->new(\$data);
cmp_ok( $trap->hostip, 'eq', "192.168.10.21", "Host ip correct");
cmp_ok( $trap->trapname, 'eq', "IF-MIB::linkDown", "trapname correct");
cmp_ok( $trap->expand('This IP is ${HOSTIP}'), 'eq', 'This IP is 192.168.10.21', '${HOSTIP} expands correctly');
    is( $trap->expand('${V55}'), "(null)", 'Expands unavailable V55');
    is( $trap->expand('${P55}'), "(null)", 'Expands unavailable P55');
    is( $trap->expand('${P8}'), "(null)", 'Got P8 with no value');
    is( $trap->expand('${V8}'), "(null)", 'Got V8 as null');
    is( $trap->expand('${P9}'), "(null)", 'Got P9 with no value (and trailing spaces)');
    is( $trap->expand('${V9}'), "(null)", 'Got V9 as null');
    is( $trap->expand('${IF-MIB::ifType}'), "ethernetCsmacd", "Removed spaces in middle and end");
cmp_ok( $trap->fully_translated, '==', 1, "Trapname is fully translated");
cmp_ok( $trap->data->{"IF-MIB::ifDescr"}, "eq", "FastEthernet0/24", "Got interface description");

$_ = $trap->expand('Port ${IF-MIB::ifIndex} (type ${IF-MIB::ifType}, description "${IF-MIB::ifDescr}") is down or ${rubbish}');
cmp_ok( $_, "eq", 'Port 24 (type ethernetCsmacd, description "FastEthernet0/24") is down or (null)',
	"Can evaluate message");

$_ = $trap->expand('Received ${TRAPNAME}: ${DUMP}');
cmp_ok( $_, "eq", 'Received IF-MIB::linkDown: IF-MIB::ifDescr=FastEthernet0/24 IF-MIB::ifIndex=24 IF-MIB::ifType=ethernetCsmacd SNMP-COMMUNITY-MIB::snmpTrapAddress=192.168.10.21 SNMPv2-MIB::snmpTrapOID=IF-MIB::linkDown SNMPv2-MIB::sysUpTime=75:22:57:17.87', "Dump correct");

cmp_ok($trap->expand('Interface ${V5} is down'), "eq", 'Interface 24 is down', 'Expansion of ${V5} correct');
cmp_ok($trap->expand('Extra data: ${P7} = ${V7}'), "eq", 'Extra data: ifType = ethernetCsmacd', 'Expansion of ${P7} and ${V7} correct');
cmp_ok($trap->expand('IP: ${P2}'), 'eq', 'IP: UDP: [192.168.10.21]:3656', '${P2} works');
cmp_ok($trap->expand('Bad - ${P}'), 'eq', 'Bad - (null)', '${P} without a number caught correctly');

$expected = 'cisco9999.lon.altinity
UDP: [192.168.10.21]:3656
SNMPv2-MIB::sysUpTime.0 75:22:57:17.87
SNMPv2-MIB::snmpTrapOID.0 IF-MIB::linkDown
IF-MIB::ifIndex.24 24
IF-MIB::ifDescr.24 FastEthernet0/24
IF-MIB::ifType.24   ethernetCsmacd  
error
error_with_spaces_at_end     
SNMP-COMMUNITY-MIB::snmpTrapAddress.0 192.168.10.21
SNMP-COMMUNITY-MIB::snmpTrapCommunity.0 "*****"';
cmp_ok( $trap->packet( {hide_passwords=>1} ), 'eq', $expected, "Passwords hidden correctly when community string on last line");

$data = <<EOF;
192.168.144.197
UDP: [192.168.144.197]:40931
SNMPv2-SMI::mib-2.1.3.0 0:1:49:29.00
SNMPv2-SMI::snmpModules.1.1.4.1.0 ISHELF-ARCS-MIB::iShelfTrapGroup.5.0
ISHELF-SYS-MIB::iShelfSysTrapDbChgOid.0 ISHELF-CARD-MIB::iShelfCardLocation.10112
ISHELF-SYS-MIB::iShelfSysSystemDateTime.0 Wrong Type (should be OCTET STRING): 27
EOF

$trap = SNMP::Trapinfo->new(\$data);
ok( ! defined $trap->trapname, "Trapname not in packet");

$data = <<EOF;
dastardly.altinity.net
10.243.196.251
SNMPv2-MIB::sysUpTime.0 119:2:04:40.34
SNMPv2-MIB::snmpTrapOID.0 CERENT-454-MIB::remoteAlarmIndication
CERENT-454-MIB::cerent454NodeTime.0 20060814114937D
CERENT-454-MIB::cerent454AlarmState.9216.remoteAlarmIndication notAlarmedNonServiceAffecting
CERENT-454-MIB::cerent454AlarmObjectType.9216.remoteAlarmIndication ds1
CERENT-454-MIB::cerent454AlarmObjectIndex.9216.remoteAlarmIndication 9216
CERENT-454-MIB::cerent454AlarmSlotNumber.9216.remoteAlarmIndication 2
CERENT-454-MIB::cerent454AlarmPortNumber.9216.remoteAlarmIndication port36
CERENT-454-MIB::cerent454AlarmLineNumber.9216.remoteAlarmIndication 0
CERENT-454-MIB::cerent454AlarmObjectName.9216.remoteAlarmIndication DS1-2-36-7
SNMP-COMMUNITY-MIB::snmpTrapAddress.0 216.243.196.251
SNMP-COMMUNITY-MIB::snmpTrapCommunity.0 "willbehidden"
EOF

$trap = SNMP::Trapinfo->new(\$data, { hide_passwords => 1 } );

cmp_ok( $trap->expand('Check for missing parameter ${ISHELF-SYS-MIB::iShelfSysTrapDbChgOid}'), "eq",
	"Check for missing parameter (null)", 'Bad macros ignore');
cmp_ok( $trap->eval('"${CERENT-454-MIB::cerent454AlarmState.*.remoteAlarmIndication}" ne "cleared"'),
	"eq", 1, "Correct expansion with wildcard");
cmp_ok( $trap->last_eval_string, 'eq', '"notAlarmedNonServiceAffecting" ne "cleared"', "Expanded correctly");
cmp_ok( $trap->eval('"${CERENT-454-MIB::cerent454AlarmState.*.remoteAlarmIndication}" eq "cleared"'),
	"eq", 0, "Correct expansion with wildcard 2");
cmp_ok( $trap->eval('"${CERENT-454-MIB::cerent454AlarmState.*.remoteAlarmIndication}" eq "notAlarmedNonServiceAffecting"'),
	"eq", 1, "Correct expansion with wildcard 3");
  isnt( $trap->match_key('CERENT-454-MIB::cerent454AlarmState.*.remoteAlarmIndication43'), "", "Should not match anything");
  isnt( $trap->match_key('CERENT-454-MIB::cerent454AlarmStaterubbish.*.remoteAlarmIndication'), "", "Should not match anything");
  isnt( $trap->match_key('CERENT-454-MIB::cerent454AlarmState.b*b.remoteAlarmIndication'), "", "Should not match anything");
  isnt( $trap->match_key('CERENT-454-MIB::cerent454AlarmState.*'), "", "Need to have same number of parts");
cmp_ok( $trap->match_key('CERENT-454-MIB::cerent454AlarmState.*.*'), "eq", "notAlarmedNonServiceAffecting", "Multiple *s work");
cmp_ok( $trap->eval('"${CERENT-454-MIB::cerent454AlarmPortNumber.*.remoteAlarmIndication}" =~ /port/'),
	"eq", 1, "Got regexp");
cmp_ok( $trap->eval('"${CERENT-454-MIB::cerent454AlarmPortNumber.*.remoteAlarmIndication}" =~ /stuff/'),
	"eq", 0, "Failed regexp");
  isnt( $trap->eval('"${CERENT-454-MIB::cerent454AlarmPortNumber.*.remoteAlarmIndication}" !=!~ /st/x'),
	"", "Syntax error");
    is( $trap->expand(""), "", "Empty string expand returns nothing");
    is( $trap->expand(), "", "Empty value expand returns nothing too");
    is( $trap->expand(0), "0", "Zero value expand returns zero");
    is( $trap->eval('"${nonexistent}" =~ /stuff/'), "0", "Empty regexp - no warnings propagated");
    is( $trap->last_eval_string, '"(null)" =~ /stuff/', "Expanded correctly");
    is( $trap->expand('${SNMP-COMMUNITY-MIB::snmpTrapCommunity}'), '"*****"', "Password hidden on input");

# Infinite loop tests
  diag "Doing infinite tests";
    is( $trap->eval('"${CERENT-454-MIB::cerent454AlarmPortNumber*}" eq "infinite"'), 0, "No infinite loop! - phew");
    


$data = <<EOF;
dastardly.altinity.net
EOF

$trap = SNMP::Trapinfo->new(\$data);
ok( ! defined $trap, "Bad packet (missing 2nd line)");



##########
# Test Safe eval's

#####
my $unsafe_opstr = <<EOF;
	open(FILE,"< /etc/passwd") or die("Can't read file /etc/passwd: $!\n");
	close(FILE);
EOF

#####
my $safe_opstr = <<EOF;
	print "";
	0;
EOF

$data = <<EOF;
dastardly.altinity.net
10.243.196.251
SNMPv2-MIB::sysUpTime.0 119:2:04:40.34
EOF
$trap = SNMP::Trapinfo->new(\$data);
ok( defined $trap, "Failed to create simple trap object");


is ( eval "$unsafe_opstr", 1, "EVAL of unsafe op succeeded" );
ok ( defined $trap->eval($safe_opstr), "Allow safe eval" );
is ( $trap->eval($unsafe_opstr), undef, "Unsafe eval denied");
like( $@, "/trapped by operation mask/", "Correct error");
ok( defined $trap->eval("1+2*3/4-5"), "Basic maths okay");
ok( defined $trap->eval('"${P1}" =~ /altinity/'), "regexp okay");
ok( defined $trap->eval("(1 > 73) && (5 < 100) || (6 != 5) and ('here' ne 'there') or ('now' lt 'yesterday')"), "comparison operators okay");
is( $trap->eval("system('/usr/bin/cat /etc/passwd')"), undef, "system call correctly blocked");
ok ( defined $trap->eval("localtime()"), "Access to timelocal OK" );

$data = <<EOF;
10.12.14.16
10.12.14.16
UDP: [10.12.14.16]:12039
DISMAN-EVENT-MIB::sysUpTimeInstance 180:5:01:15.28
SNMPv2-MIB::snmpTrapOID.0 JUNIPER-IVE-MIB::logMessageTrap
JUNIPER-IVE-MIB::logID "SYS12345"
JUNIPER-IVE-MIB::logType "critical"
JUNIPER-IVE-MIB::logDescription "critical - System()[] - 2000/01/01 01:01:01 - Sending iveLogNearlyFull SNMP trap to 10.12.14.16:162"
EOF
$trap = SNMP::Trapinfo->new(\$data);
ok( defined $trap, "Failed to create trap object");
is( $trap->expand('${TRAPNAME}'), "JUNIPER-IVE-MIB::logMessageTrap", "Trapname match");

my $check= <<'EOF';
"${TRAPNAME}" eq "JUNIPER-IVE-MIB::logMessageTrap" && ${JUNIPER-IVE-MIB::logType} eq "critical"
EOF

ok ( defined($trap->eval("$check")), "EVAL of JUNIPER check succeeded" );

$data = <<EOF;
cisco9999.lon.altinity
UDP: [192.168.10.21]:3656->[10.10.10.10]
SNMPv2-MIB::sysUpTime.0 75:22:57:17.87
SNMPv2-MIB::snmpTrapOID.0 IF-MIB::linkDown
IF-MIB::ifIndex.24 24
IF-MIB::ifDescr.24 FastEthernet0/24
IF-MIB::ifType.24   ethernetCsmacd  
EOF

eval '$trap = SNMP::Trapinfo->new($data)';
like( $@, '/Bad ref/', "Complain if bad parameters for new()");

$trap = SNMP::Trapinfo->new(\$data);
cmp_ok( $trap->hostip, 'eq', "192.168.10.21", "Host ip correct");
