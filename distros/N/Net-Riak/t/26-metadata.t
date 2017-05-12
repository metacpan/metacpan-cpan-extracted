use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak {
    my ($client, $bucket_name) = @_;
    my $content = '{ "dummy":"content"}';
    ok my $bucket = $client->bucket($bucket_name),
        'created bucket object ok';

    {
    ok my $obj = $bucket->new_object('metaobj', $content),
        'created a new riak object to hold our metadata';
    ok $obj->set_meta( mymeta => 'metavalue'),
        '... and can add metadata to it';
    ok my $meta_value = $obj->get_meta('mymeta'),
        '... and can retrieve our metadata from the object';
    is $meta_value, 'metavalue',
        '... and metadata has correct value';

    # setting meta overwrites the value; no support for multivalue headers
    ok $obj->set_meta( mymeta => 'newvalue' ),
        '... and can update the metadata';
    ok $meta_value = $obj->get_meta('mymeta'),
        '... and can retrieve new metadata from the object';
    is $meta_value, 'newvalue',
        '... and metadata has new value';
    ok $obj->store,
        '... and our object with metadata can be stored ok';

    }

    {
    ok my $obj = $bucket->get('metaobj'),
        'Can retrieve object';
    is $obj->has_meta, 1,
        '... and object says it has one piece of metadata';

    ok my $meta_value = $obj->get_meta('mymeta'),
        '... and can retrieve our metadata from the object';
    is $meta_value, 'newvalue',
        '... and metadata has expected value';

    ok $obj->set_meta( meta2 => 'metavalue2' ),
        'Can add a second meta';
    is $obj->has_meta, 2,
        '... and meta counter is incremented';

    ok $obj->store,
        "... and object can be stored again";
    }

    {
    my $obj = $bucket->get('metaobj');
    is $obj->has_meta, 2,
        'Object says it now has two pieces of metadata';
    ok $obj->get_meta('meta2'),
        "... and second meta can be accessed";
    is $obj->get_meta('meta2'), 'metavalue2',
        '... and has expected value';

    my $expected = {'meta2' => 'metavalue2', 'mymeta' => 'newvalue' };
    is_deeply {$obj->all_meta}, $expected,
        "... and all_meta gives us both metas in a hash";

    ok $obj->remove_meta('meta2'),
        'Can remove an individual meta';
    is $obj->has_meta, 1,
        '... and meta counter is decremented';

    ok !$obj->remove_meta('meta2'),
        'Double-removing the now-non-existant item returns false';
    is $obj->has_meta, 1,
        '... and meta counter is not decremented';
    ok $obj->store,
        "... and object can be stored again";

    }

    {
    my $obj = $bucket->get('metaobj');
    ok !$obj->get_meta('meta2'),
        "Deleted meta is no longer available";
    is $obj->get_meta('mymeta'), 'newvalue',
        '... but non-deleted meta is still present';
    }


    # cannot add undef values via set_meta
    {
    my $obj = $bucket->get('metaobj');
    eval {
        $obj->set_meta( meta3 => undef )
    };

    like $@, qr/Validation failed for 'Str' with value undef/,
        "Cannot add meta with undef value";
    is $obj->has_meta, 1,
        '... and meta counter is unchanged by trying to add invalid data';
    }

    my $obj = $bucket->get('metaobj');
    $obj->delete; # teardown
};

