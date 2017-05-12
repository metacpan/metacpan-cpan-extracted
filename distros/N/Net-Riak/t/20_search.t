use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak_rest {
    my ($client, $bucket_name) = @_;
    ok $client->setup_indexing($bucket_name), 'setup indexing ok';

    ok my $bucket = $client->bucket($bucket_name), 'got bucket test';
    my $content = { field => "indexed" };

    ok my $obj = $bucket->new_object(undef, $content),
      'created a new riak object without a key';
    ok $obj->store, 'store object without key';
    ok $obj->key, 'key created';

    is $client->search(
        index => $bucket_name,
        wt => "json",
        q => "field:indexed")->{response}->{docs}[0]->{id},
        $obj->key,
        'search with index in path';

    is $client->search(
        wt => "json",
        q => "$bucket_name.field:indexed")->{response}->{docs}[0]->{id},
        $obj->key,
        'search with index prefixes in query';
    $obj->delete;
}
