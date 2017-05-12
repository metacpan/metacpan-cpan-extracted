
use strict;
use warnings;
use Test::More;

BEGIN { $ENV{PROTOCOL_OTR_ENABLE_QUICK_RANDOM} = 1 }

use Protocol::OTR qw( POLICY_OPPORTUNISTIC :error_codes );

is(POLICY_OPPORTUNISTIC, 118, "POLICY_OPPORTUNISTIC exported");
is(ERRCODE_NONE, 0, "ERRCODE_NONE exported via :error_codes");
is(ERRCODE_ENCRYPTION_ERROR, 1, "ERRCODE_NONE exported via :error_codes");
is(ERRCODE_MSG_NOT_IN_PRIVATE, 2, "ERRCODE_NONE exported via :error_codes");
is(ERRCODE_MSG_UNREADABLE, 3, "ERRCODE_NONE exported via :error_codes");
is(ERRCODE_MSG_MALFORMED, 4, "ERRCODE_NONE exported via :error_codes");

done_testing();

