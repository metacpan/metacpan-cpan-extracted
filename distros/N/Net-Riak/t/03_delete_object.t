use lib 't/lib';
use Test::More;
use Test::Riak;
use Data::Dumper;

test_riak {
    my ($client, $bucket_name) = @_;

    my $bucket  = $client->bucket($bucket_name);
    my $content = [int(rand(100))];
    my $obj     = $bucket->new_object('foo', $content);
    ok $obj->store, 'object is stored';
    $obj = $bucket->get('foo');
    ok $obj->exists, 'object exists';
    $obj->delete;
    ok $obj->exists, " exists after delete";
    $obj->load;
    ok !$obj->exists, "object don't exists after load";
    is scalar(@{$bucket->get_keys}), 0, "no keys left in bucket";
};
