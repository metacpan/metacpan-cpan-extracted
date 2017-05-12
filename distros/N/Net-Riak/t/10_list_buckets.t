use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak {
    my ($client, $bucket_name) = @_;

    my $bucket = $client->bucket($bucket_name."_1");
    ok $bucket->new_object( "bob" => { 'name' => 'bob', age => 23 } )->store, 'store';

    $bucket = $client->bucket($bucket_name."_2");
    ok $bucket->new_object( "bob" => { 'name' => 'bob', age => 23 } )->store, 'store';

    ok scalar( $client->all_buckets) >= 2, 'listed buckets';
};
