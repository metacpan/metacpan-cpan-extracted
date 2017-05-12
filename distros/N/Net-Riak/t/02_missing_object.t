use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak {
    my ($client, $bucket_name) = @_;
    my $bucket = $client->bucket($bucket_name);
    my $obj    = $bucket->get("missing");
    ok !$obj->data, 'no data';
};
