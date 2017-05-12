use strict;
use warnings;
use Test::More tests => 7;
use Net::SNMP::Util::OID;	# no import group here

Net::SNMP::Util::OID::import("Net::SNMP::Util::OID", "sys*");
is(	oid("sysObjectID"),		"1.3.6.1.2.1.1.2.0",		"system* - oid()");
is(	oidt("1.3.6.1.2.1.1.2.0"),	"sysObjectID",			"system* - oidt()");
isnt(	oid("ifDescr"),			"1.3.6.1.2.1.2.2.1.2",		"system* - exclusion");

Net::SNMP::Util::OID::import("Net::SNMP::Util::OID", "if*");
is(	oid("ifDescr"),			"1.3.6.1.2.1.2.2.1.2",		"interfaces* - oid(ifDescr)");
is(	oidt("1.3.6.1.2.1.2.2.1.2"),	"ifDescr",			"interfaces* - oidt()");
is(	oid("ifName"),			"1.3.6.1.2.1.31.1.1.1.1",	"interfaces* - oid(ifName)");
is(	oidt("1.3.6.1.2.1.31.1.1.1.1"),	"ifName",			"interfaces* - oidt()");
