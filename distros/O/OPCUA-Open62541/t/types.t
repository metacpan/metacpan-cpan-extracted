use strict;
use warnings;
use OPCUA::Open62541 ':limit';

use Test::More tests => 20;
use Test::NoWarnings;

ok(defined(OPCUA::Open62541::TRUE()), "name space");
ok(TRUE,			"true");
ok(!FALSE,			"false");
is(SBYTE_MIN,	-(1<<7),	"sbyte min");
is(SBYTE_MAX,	(1<<7)-1,	"sbyte max");
is(BYTE_MIN,	0,		"byte min");
is(BYTE_MAX,	(1<<8)-1,	"byte max");
is(INT16_MIN,	-(1<<15),	"int16 min");
is(INT16_MAX,	(1<<15)-1,	"int16 max");
is(UINT16_MIN,	0,		"uint16 min");
is(UINT16_MAX,	(1<<16)-1,	"uint16 max");
is(INT32_MIN,	-(1<<31),	"int32 min");
is(INT32_MAX,	(1<<31)-1,	"int32 max");
is(UINT32_MIN,	0,		"uint32 min");
is(UINT32_MAX,	0xffffffff,	"uint32 max");
# XXX this only works for Perl on 64 bit platforms
is(INT64_MIN,	-(1<<63),	"int64 min");
is(INT64_MAX,	(1<<63)-1,	"int64 max");
is(UINT64_MIN,	0,		"uint64 min");
is(UINT64_MAX,	18446744073709551615,	"uint64 max");
