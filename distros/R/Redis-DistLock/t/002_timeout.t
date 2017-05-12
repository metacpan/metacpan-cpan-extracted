
use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "needs TEST_SERVER variable for server testing"
        unless $ENV{TEST_SERVER};
}

use_ok( "Redis::DistLock" );

my $rd = Redis::DistLock->new(
    servers => [ split( m!,!, $ENV{TEST_SERVER} ) ],
);

my $lock = $rd->lock( "foo", 1 );

ok( $lock, "got a lock" );

ok( ! $rd->lock( "foo", 1 ), "already locked" );

sleep( 1 );

ok( $lock, "old lock gone - got a new one" );

done_testing();

# vim: ts=4 sw=4 et:
