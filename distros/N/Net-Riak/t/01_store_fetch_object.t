use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak {
    my ($client, $bucket_name) = @_;
    ok my $bucket = $client->bucket($bucket_name), 'got bucket test';
    my $content = [int(rand(100))];
    ok my $obj = $bucket->new_object('foo', $content),
      'created a new riak object';

    ok $obj->store, 'store object foo';

    if ($obj->client->can('status')) {
        is $obj->client->status, 200, 'valid status';
    }

    is $obj->key, 'foo', 'valid key';
    is_deeply $obj->data, $content, 'valid content';
};

test_riak_rest {
    my ($client, $bucket_name) = @_;
    ok my $bucket = $client->bucket($bucket_name), 'got bucket test';
    my $content = [int(rand(100))];

    ok my $obj = $bucket->new_object(undef, $content),
      'created a new riak object without a key';
    ok $obj->store, 'store object without key';
    ok $obj->key, 'key created';
}
