
use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "needs TEST_SERVER variable for server testing"
        unless $ENV{TEST_SERVER};
}

use_ok( "Redis::DistLock" );

my @hosts = qw( foo bar baz );
my @rds;

# connect multiple redis instances
for my $n ( 0 .. $#hosts ) {
    my $host = $hosts[ $n ];
    my $rd = Redis::DistLock->new(
        servers => [ split( m!,!, $ENV{TEST_SERVER} ) ],
    );

    $rds[ $n ] = $rd;
}

# take a random one to get a lock
my $pick = int rand $#rds;

my $lock = $rds[ $pick ]->lock( "foo", 1, $hosts[ $pick ] );

ok( $lock, "got a lock" );

for my $n ( grep $_ != $pick, 0 .. $#rds ) {
    ok( ! $rds[ $n ]->lock( "foo", 1, $hosts[ $n ] ), "already locked" );
}

$rds[ $pick ]->release( $lock );

done_testing();

# vim: ts=4 sw=4 et:
