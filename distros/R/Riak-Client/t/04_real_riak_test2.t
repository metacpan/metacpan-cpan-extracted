use strict;
use warnings;
BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More;
use Test::Exception;
use Riak::Client;

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

my $client1 = Riak::Client->new(
    host => $host,
    port => $port,
);

my $client2 = Riak::Client->new(
    host => $host,
    port => $port,
);

foreach my $i (0..50) {
    $client1->put(bucket => 'foo1' => ['bar']);
    $client1->get(bucket => 'foo1');
    $client2->put(bucket => 'foo2' => ['bar']);
    $client2->get(bucket => 'foo2');
}

ok(1);

done_testing;
