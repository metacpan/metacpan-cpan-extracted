use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak_rest {
    my ($client, $bucket_name) = @_;
    my $content = { field => "2index" };
    ok my $bucket = $client->bucket($bucket_name), 'got bucket test';
    ok my $obj = $bucket->new_object('2ikey', $content),
        'created a new riak object for seconday index';
    ok $obj->add_index('myindex_bin', 'value'), 'Secondary index created';

    ok $obj->store, 'Object with secondary index stored';
    ok my $newobj = $bucket->get('2ikey'), 'Object with secondary index retrieved';
    ok $newobj->remove_index('myindex_bin', 'value'), 'Secondary index removed';
    ok $newobj->store, "Object without secondary index saved";
}
