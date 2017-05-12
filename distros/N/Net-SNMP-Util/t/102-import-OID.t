use strict;
use warnings;
use Test::More tests => 7;
use Net::SNMP::Util::OID;	# no import group here

Net::SNMP::Util::OID::import("Net::SNMP::Util::OID", "system*");
is(	oid("sysObjectID"),		"1.3.6.1.2.1.1.2.0",		"system* - oid()");
is(	oidt("1.3.6.1.2.1.1.2.0"),	"sysObjectID",			"system* - oidt()");
isnt(	oid("ifDescr"),			"1.3.6.1.2.1.2.2.1.2",		"system* - exclusion");

Net::SNMP::Util::OID::import("Net::SNMP::Util::OID", "interfaces*");
is(	oid("ifDescr"),			"1.3.6.1.2.1.2.2.1.2",		"interfaces* - oid()");
is(	oidt("1.3.6.1.2.1.2.2.1.2"),	"ifDescr",			"interfaces* - oidt()");

Net::SNMP::Util::OID::import("Net::SNMP::Util::OID", "*");
is(	oid("ifMIBObjects"),		"1.3.6.1.2.1.31.1",		"* - oid()");
is(	oidt("1.3.6.1.2.1.31.1"),	"ifMIBObjects",			"* - oidt()");
