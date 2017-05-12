
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

my $lock = $rd->lock( "foo", 10, "THAT" );

ok( $lock, "got a fresh lock" );

for ( 1 .. 3 ) {
    my $more = $rd->lock( "foo", 10, "THAT", 1 );

    ok( $more, "extended the lock!" );
}

$rd->release( $lock );

done_testing();

# vim: ts=4 sw=4 et:
