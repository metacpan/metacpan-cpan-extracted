use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 20;
use Test::NoWarnings;

ok(defined(OPCUA::Open62541::TRUE()),			"name space");
ok(OPCUA::Open62541::TRUE,				"true");
ok(!OPCUA::Open62541::FALSE,				"false");
is(OPCUA::Open62541::SBYTE_MIN,		-(1<<7),	"sbyte min");
is(OPCUA::Open62541::SBYTE_MAX,		(1<<7)-1,	"sbyte max");
is(OPCUA::Open62541::BYTE_MIN,		0,		"byte min");
is(OPCUA::Open62541::BYTE_MAX,		(1<<8)-1,	"byte max");
is(OPCUA::Open62541::INT16_MIN,		-(1<<15),	"int16 min");
is(OPCUA::Open62541::INT16_MAX,		(1<<15)-1,	"int16 max");
is(OPCUA::Open62541::UINT16_MIN,	0,		"uint16 min");
is(OPCUA::Open62541::UINT16_MAX,	(1<<16)-1,	"uint16 max");
is(OPCUA::Open62541::INT32_MIN,		-(1<<31),	"int32 min");
is(OPCUA::Open62541::INT32_MAX,		(1<<31)-1,	"int32 max");
is(OPCUA::Open62541::UINT32_MIN,	0,		"uint32 min");
is(OPCUA::Open62541::UINT32_MAX,	0xffffffff,	"uint32 max");
# XXX this only works for Perl on 64 bit platforms
is(OPCUA::Open62541::INT64_MIN,		-(1<<63),	"int64 min");
is(OPCUA::Open62541::INT64_MAX,		(1<<63)-1,	"int64 max");
is(OPCUA::Open62541::UINT64_MIN,	0,		"uint64 min");
is(OPCUA::Open62541::UINT64_MAX,	18446744073709551615,	"uint64 max");
