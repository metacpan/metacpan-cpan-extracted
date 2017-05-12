#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib qw(
    lib
    t/tlib
);

use Test::More;
plan 'no_plan';

BEGIN {
    eval 'use Test::RedisServer';               ## no critic
    plan skip_all => 'because Test::RedisServer required for testing' if $@;
}

BEGIN {
    eval 'use Test::NoWarnings';                ## no critic
    plan skip_all => 'because Test::NoWarnings required for testing' if $@;
}

use Digest::SHA1 qw(
    sha1_hex
);
use Redis;
use Redis::CappedCollection::Test::Utils qw(
    verify_redis
);

# -- Global variables
my (
    $ERROR_MSG,
    $REDIS,
    $REDIS_SERVER,
);

# http://redis.io/commands/eval
#
# Operations performed by the script cannot depend on any hidden (non-explicit) information or state
# that may change as script execution proceeds or between different executions of the script,
# nor can it depend on any external input from I/O devices.
#
# Global variables protection
#
# Redis scripts are not allowed to create global variables,
# in order to avoid leaking data into the Lua state.
# If a script needs to maintain state between calls (a pretty uncommon need)
# it should use Redis keys instead.
#
# Note for Lua newbies: in order to avoid using global variables in your scripts
# simply declare every variable you are going to use using the local keyword.

my $script_body = "
local foo = redis.call( 'GET', 'foo' );
foo = foo + 1;
redis.call( 'SET', 'foo', foo );

local bar = 0;
bar = bar + 1;

return bar;
";

( $REDIS_SERVER, $ERROR_MSG ) = verify_redis();

SKIP: {
    diag $ERROR_MSG if $ERROR_MSG;
    skip( $ERROR_MSG, 1 ) if $ERROR_MSG;

    $REDIS = Redis->new( $REDIS_SERVER->connect_info );
    is $REDIS->ping, 'PONG', 'redis server available';

    my $i = 0;
    # control key
    $REDIS->set( 'foo', $i );

    my $sha1 = sha1_hex( $script_body );
    for ( ; $i < 10; ++$i ) {
        my $foo_key_value = $REDIS->get( 'foo' );
        is $foo_key_value, $i, "'foo' before the script call is OK";

        my $bar_variable_value;
        if ( $REDIS->script_exists( $sha1 )->[0] ) {
            pass 'previously loaded script call';
            $bar_variable_value = $REDIS->evalsha( $sha1, 0 );
        } else {
            pass 'the first script call';
            $bar_variable_value = $REDIS->eval( $script_body, 0 );
        }
        is $bar_variable_value, 1, "'bar' not changed between the script calls";

        $foo_key_value = $REDIS->get( 'foo' );
        is $foo_key_value, $i + 1, "'foo' after the script call increments";
    }
}
