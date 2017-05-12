# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-RDEP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

BEGIN { use_ok('XML::Idiom') };

my $idiom_xml ='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><events xmlns="http://www.cisco.com/cids/idiom" schemaVersion="2.00"><evAlert eventId="1096366091217700320" severity="low"><originator><hostId>rdepServer</hostId><appName>sensorApp</appName><appInstanceId>332</appInstanceId></originator><time offset="0" timeZone="UTC">1096473433893588000</time><signature sigName="TEST-SIG" sigId="20001" subSigId="0" version="1.0">test-string</signature><interfaceGroup></interfaceGroup><vlan>0</vlan><participants><attack><attacker><addr locality="OUT">192.168.1.1</addr><port>16091</port></attacker><victim><addr locality="OUT">172.16.1.1</addr><port>443</port></victim></attack></participants></evAlert></events>';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $i = XML::Idiom->new($idiom_xml);
ok(defined($i), 'new() works');

is($i->getNumberOfEvents, 1, 'processing events works');

my $e = $i->getNextEvent();
my $h =  $e->{ participants }->{ attack }->{ attacker }->{ addr }->{ content };
is($h, '192.168.1.1', 'contents validated');
