use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak {
    my ($client, $bucket_name) = @_;

    my $bucket  = $client->bucket($bucket_name);

    for (1..4) {
        my $obj = $bucket->new_object("foo$_", [ "foo_test" ]);
        ok $obj->store, 'object is stored';
    }

    my $keys = $bucket->get_keys;

    is_deeply [sort @$keys], [ map { "foo$_" } 1..4 ], "got keys";


    my @keys2;

    $bucket->get_keys( {
            stream => 'true',
            cb     => sub {
                ok 1, "call back called for $_[0]";
                push @keys2, $_[0];
            }
        }
    );

    $bucket->delete_object($_) for @keys2;

    $keys = $bucket->get_keys;

    is scalar @$keys, 0, "deleted keys";
};
