#!perl -T

use Test::More tests => 4;
use Schedule::AdaptiveThrottler qw(set_client authorize);

ok(defined &set_client, "set_client() imported");
ok(defined &authorize, "authorize() imported");
ok(defined SCHED_ADAPTHROTTLE_BLOCKED, "Block constant defined");
ok(defined SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorize constant defined");

