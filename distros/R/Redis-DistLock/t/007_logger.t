
use strict;
use warnings;

use lib qw( t/lib );
use My::Redis;

use Test::More;

use_ok( "Redis::DistLock" );

my $redis = bless( { version => "2.6.12" }, "My::Redis" );
my $counter = 0;

my $rd = Redis::DistLock->new(
    servers => [ $redis ],
    logger  => sub { $counter++ },
);

my $lock = $rd->lock( "testit", 10 );

ok( ! $lock, "got no lock" );

is( $counter, $rd->{retry_count}, "failed and logged three times" );


$rd = Redis::DistLock->new(
    servers => [ $redis ],
    logger  => undef,
);
$lock = $rd->lock( "testit", 10 );
ok( ! $lock, "no lock, no logger, no noise" );


done_testing();

# vim: ts=4 sw=4 et:
